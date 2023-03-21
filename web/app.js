const relay = window.NostrTools.relayInit('wss://relay.damus.io');

async function _retryConnect() {
    await new Promise(resolve => setTimeout(resolve, 10000));
    _connectRelays();
}

async function connecteToRelay() {
    relay.on('connect', () => {
        return true;
    })
    relay.on('error', async () => {
        await _retryConnect();
        return false;
    })
    await relay.connect();
}

async function sendDm(message, senderSk, senderPk, receiverPk) {
    let ciphertext = await window.NostrTools.nip04.encrypt(senderSk, receiverPk, message);

    let event = {
        kind: 4,
        pubkey: senderPk,
        tags: [['p', receiverPk]],
        content: ciphertext,
        created_at: Math.floor(Date.now() / 1000)
    }

    event.id = window.NostrTools.getEventHash(event);
    event.sig = window.NostrTools.signEvent(event, senderSk);

    let pub = relay.publish(event)
    pub.on('ok', () => {
        return true;
    })
    pub.on('failed', reason => {
        return false;
    })
}

function nsecEncode(sk) {
    return window.NostrTools.nip19.nsecEncode(sk);
}

function npubEncode(pk) {
    return window.NostrTools.nip19.npubEncode(pk);
}