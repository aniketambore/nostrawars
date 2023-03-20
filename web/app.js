async function encryptMessage(sk1, pk2, message) {
    if (window.NostrTools && window.NostrTools.nip04 && window.NostrTools.nip04.encrypt) {
        let ciphertext = await window.NostrTools.nip04.encrypt(sk1, pk2, message);
        return ciphertext;
    } else {
        throw new Error('Error encrypting message');
    }
}

async function decryptMessage(sk1, pk2, message) {
    if (window.NostrTools && window.NostrTools.nip04 && window.NostrTools.nip04.decrypt) {
        let plaintext = await window.NostrTools.nip04.decrypt(sk1, pk2, message);
        return plaintext;
    } else {
        throw new Error('Error decrypting message');
    }
}