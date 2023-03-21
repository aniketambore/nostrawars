const relay = window.NostrTools.relayInit('wss://relay.damus.io');

async function _retryConnect(connectedCallback, sk1, pk1, eventReceivedCallback) {
    await new Promise(resolve => setTimeout(resolve, 10000));
    _connectRelays(connectedCallback, sk1, pk1, eventReceivedCallback);
}

async function connectToRelay(connectedCallback, sk1, pk1, eventReceivedCallback) {
    relay.on('connect', () => {
        connectedCallback();
    });
    relay.on('error', async () => {
        await _retryConnect(connectedCallback, sk1, pk1, eventReceivedCallback);
    });

    relay.on('disconnect', async () => {
        await _retryConnect(connectedCallback, sk1, pk1, eventReceivedCallback);
    });

    await relay.connect();

    let sub = relay.sub([{
        kinds: [4],
        since: Math.floor(Date.now() / 1000),
        '#p': [pk1]
    }]);

    sub.on('event', (event) => {
        console.log(`sub1 got event: ${JSON.stringify(event)}`);
        _decryptText(event, sk1, eventReceivedCallback);
    });
}

async function _decryptText(event, sk1, eventReceivedCallback) {
    let plaintext = await window.NostrTools.nip04.decrypt(sk1, event.pubkey, event.content);
    eventReceivedCallback(plaintext, event.pubkey);
}

async function sendDm(message, senderSk, senderPk, receiverPk, onPublishSuccessCallback) {
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
        onPublishSuccessCallback(message);
    })
    pub.on('failed', reason => {
        console.log(`failed to publish to ${relay.url}: ${reason}`)
    })
}

function nsecEncode(sk) {
    return window.NostrTools.nip19.nsecEncode(sk);
}

function npubEncode(pk) {
    return window.NostrTools.nip19.npubEncode(pk);
}

function closeRelay() {
    relay.close();
}