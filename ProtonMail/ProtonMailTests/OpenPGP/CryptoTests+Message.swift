//
//  CryptoTests+Message.swift
//  ProtonMail - Created on 09/12/19.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import XCTest
import Crypto
@testable import ProtonMail


extension CryptoTests {
    
    func testIOSSignedMessageDecryption() {
        guard let keyringPrivateKey = OpenPGPTestsDefine.keyring_privateKey.rawValue,
            let mimePublicKey = OpenPGPTestsDefine.mime_publicKey.rawValue,
            let messageSigned = OpenPGPTestsDefine.message_signed.rawValue,
            let messagePlaintext = OpenPGPTestsDefine.message_plaintext.rawValue,
            let keyringPublicKey = OpenPGPTestsDefine.keyring_publicKey.rawValue else {
                XCTFail("can't be nil")
                return
        }
        let pgp = Crypto()
        do {
            let decrypted = try pgp.decryptVerify(encrytped: messageSigned,
                                                  publicKey: mimePublicKey,
                                                  privateKey: keyringPrivateKey,
                                                  passphrase: self.testMailboxPassword, verifyTime: 0)
            XCTAssertNotNil(decrypted)
            XCTAssertNotNil(decrypted!.message)
            let clearMessage = decrypted!.message!.getString()
            XCTAssertEqual(messagePlaintext, clearMessage)
            XCTAssertNotNil(decrypted!.signatureVerificationError)
            let status = decrypted!.signatureVerificationError!.status
            XCTAssertEqual(2, status)
            
            guard let pgpMessage = try pgp.encrypt(plainText: clearMessage,
                                                   publicKey: keyringPublicKey,
                                                   privateKey: keyringPrivateKey,
                                                   passphrase: self.testMailboxPassword) else {
                                                    XCTFail("can't be nil")
                                                    return
            }
            
            let decrypted1 = try pgp.decryptVerify(encrytped: pgpMessage,
                                                   publicKey: keyringPublicKey,
                                                   privateKey: keyringPrivateKey,
                                                   passphrase: self.testMailboxPassword, verifyTime: 0)
            XCTAssertNotNil(decrypted1)
            XCTAssertNotNil(decrypted1!.message)
            let clearMessage1 = decrypted1!.message!.getString()
            XCTAssertEqual(messagePlaintext, clearMessage1)
            XCTAssertNil(decrypted1!.signatureVerificationError) //if none means ok
            
            
            do {
                _ = try pgp.decryptVerify(encrytped: pgpMessage,
                                          publicKey: keyringPublicKey,
                                          privateKey: keyringPublicKey,
                                          passphrase: self.testMailboxPassword, verifyTime: 0)
                XCTFail("can't be here")
            } catch {
                
            }
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    
    
    func testTextMessageEncryptionWithSymmetricKey() {
        let encodedKey: String = "ExXmnSiQ2QCey20YLH6qlLhkY3xnIBC1AwlIXwK/HvY="
        let decodedSymmetricKey : Data = encodedKey.decodeBase64()
        let testSymmetricKey = CryptoCreateSymmetricKey(decodedSymmetricKey.mutable as Data, "aes256")
        let testWrongSymmetricKey = CryptoNewSymmetricKeyFromToken("WrongPass", "aes256")
        let message = CryptoNewPlainMessageFromString("The secret code is... 1, 2, 3, 4, 5")
        XCTAssertNotNil(testSymmetricKey)
        XCTAssertNotNil(testWrongSymmetricKey)
        XCTAssertNotNil(message)
        do {
            // Encrypt data with password
            let encrypted = try testSymmetricKey!.encrypt(message!)
            do {
                // Decrypt data with wrong password
                _ = try testWrongSymmetricKey!.decrypt(encrypted)
                XCTFail("shouldn't go catch")
            } catch {  }
            // Decrypt data with the good password
            let decrypted = try testSymmetricKey!.decrypt(encrypted)
            XCTAssertEqual( message!.getString(), decrypted.getString())
        } catch let error {
            XCTFail("thrown" + "\(error.localizedDescription)")
        }
    }
    //
    //    func TestBinaryMessageEncryptionWithSymmetricKey(t *testing.T) {
    //        binData, _ := base64.StdEncoding.DecodeString("ExXmnSiQ2QCey20YLH6qlLhkY3xnIBC1AwlIXwK/HvY=")
    //        var message = NewPlainMessage(binData)
    //
    //        // Encrypt data with password
    //        encrypted, err := testSymmetricKey.Encrypt(message)
    //        if err != nil {
    //            t.Fatal("Expected no error when encrypting, got:", err)
    //        }
    //        // Decrypt data with wrong password
    //        _, err = testWrongSymmetricKey.Decrypt(encrypted)
    //        assert.NotNil(t, err)
    //
    //        // Decrypt data with the good password
    //        decrypted, err := testSymmetricKey.Decrypt(encrypted)
    //        if err != nil {
    //            t.Fatal("Expected no error when decrypting, got:", err)
    //        }
    //        assert.Exactly(t, message, decrypted)
    //    }
    //
    //    func TestTextMessageEncryption(t *testing.T) {
    //        var message = NewPlainMessageFromString("plain text")
    //
    //        testPublicKeyRing, _ = pgp.BuildKeyRingArmored(readTestFile("keyring_publicKey", false))
    //        testPrivateKeyRing, err = pgp.BuildKeyRingArmored(readTestFile("keyring_privateKey", false))
    //
    //        // Password defined in keyring_test
    //        err = testPrivateKeyRing.UnlockWithPassphrase(testMailboxPassword)
    //        if err != nil {
    //            t.Fatal("Expected no error unlocking privateKey, got:", err)
    //        }
    //
    //        ciphertext, err := testPublicKeyRing.Encrypt(message, testPrivateKeyRing)
    //        if err != nil {
    //            t.Fatal("Expected no error when encrypting, got:", err)
    //        }
    //
    //        decrypted, err := testPrivateKeyRing.Decrypt(ciphertext, testPublicKeyRing, pgp.GetUnixTime())
    //        if err != nil {
    //            t.Fatal("Expected no error when decrypting, got:", err)
    //        }
    //        assert.Exactly(t, message.GetString(), decrypted.GetString())
    //    }
    //
    //    func TestBinaryMessageEncryption(t *testing.T) {
    //        binData, _ := base64.StdEncoding.DecodeString("ExXmnSiQ2QCey20YLH6qlLhkY3xnIBC1AwlIXwK/HvY=")
    //        var message = NewPlainMessage(binData)
    //
    //        testPublicKeyRing, _ = pgp.BuildKeyRingArmored(readTestFile("keyring_publicKey", false))
    //        testPrivateKeyRing, err = pgp.BuildKeyRingArmored(readTestFile("keyring_privateKey", false))
    //
    //        // Password defined in keyring_test
    //        err = testPrivateKeyRing.UnlockWithPassphrase(testMailboxPassword)
    //        if err != nil {
    //            t.Fatal("Expected no error unlocking privateKey, got:", err)
    //        }
    //
    //        ciphertext, err := testPublicKeyRing.Encrypt(message, testPrivateKeyRing)
    //        if err != nil {
    //            t.Fatal("Expected no error when encrypting, got:", err)
    //        }
    //
    //        decrypted, err := testPrivateKeyRing.Decrypt(ciphertext, testPublicKeyRing, pgp.GetUnixTime())
    //        if err != nil {
    //            t.Fatal("Expected no error when decrypting, got:", err)
    //        }
    //        assert.Exactly(t, message.GetBinary(), decrypted.GetBinary())
    //
    //        // Decrypt without verifying
    //        decrypted, err = testPrivateKeyRing.Decrypt(ciphertext, nil, 0)
    //        if err != nil {
    //            t.Fatal("Expected no error when decrypting, got:", err)
    //        }
    //        assert.Exactly(t, message.GetString(), decrypted.GetString())
    //    }
    //
    //    func TestIssue11(t *testing.T) {
    //        myKeyring, err := pgp.BuildKeyRingArmored(readTestFile("issue11_privatekey", false))
    //        if err != nil {
    //            t.Fatal("Expected no error while bulding private keyring, got:", err)
    //        }
    //
    //        err = myKeyring.UnlockWithPassphrase("1234");
    //        if err != nil {
    //            t.Fatal("Expected no error while unlocking private keyring, got:", err)
    //        }
    //
    //        senderKeyring, err := pgp.BuildKeyRingArmored(readTestFile("issue11_publickey", false))
    //        if err != nil {
    //            t.Fatal("Expected no error while building public keyring, got:", err)
    //        }
    //
    //        assert.Exactly(t, []uint64{0x643b3595e6ee4fdf}, senderKeyring.KeyIds())
    //
    //        pgpMessage, err := NewPGPMessageFromArmored(readTestFile("issue11_message", false))
    //        if err != nil {
    //            t.Fatal("Expected no error while unlocking private keyring, got:", err)
    //        }
    //
    //        plainMessage, err := myKeyring.Decrypt(pgpMessage, senderKeyring, 0)
    //        if err != nil {
    //            t.Fatal("Expected no error while decrypting/verifying, got:", err)
    //        }
    //
    //        assert.Exactly(t, "message from sender", plainMessage.GetString())
    //    }
    //
    //    func TestSignedMessageDecryption(t *testing.T) {
    //        testPrivateKeyRing, err = pgp.BuildKeyRingArmored(readTestFile("keyring_privateKey", false))
    //
    //        // Password defined in keyring_test
    //        err = testPrivateKeyRing.UnlockWithPassphrase(testMailboxPassword)
    //        if err != nil {
    //            t.Fatal("Expected no error unlocking privateKey, got:", err)
    //        }
    //
    //        pgpMessage, err := NewPGPMessageFromArmored(readTestFile("message_signed", false))
    //        if err != nil {
    //            t.Fatal("Expected no error when unarmoring, got:", err)
    //        }
    //
    //        decrypted, err := testPrivateKeyRing.Decrypt(pgpMessage, nil, 0)
    //        if err != nil {
    //            t.Fatal("Expected no error when decrypting, got:", err)
    //        }
    //        assert.Exactly(t, readTestFile("message_plaintext", true), decrypted.GetString())
    //    }
    //
    //    func TestMultipleKeyMessageEncryption(t *testing.T) {
    //        var message = NewPlainMessageFromString("plain text")
    //
    //        testPublicKeyRing, _ = pgp.BuildKeyRingArmored(readTestFile("keyring_publicKey", false))
    //        err = testPublicKeyRing.ReadFrom(strings.NewReader(readTestFile("mime_publicKey", false)), true)
    //        if err != nil {
    //            t.Fatal("Expected no error adding second public key, got:", err)
    //        }
    //
    //        assert.Exactly(t, 2, len(testPublicKeyRing.entities))
    //
    //        testPrivateKeyRing, err = pgp.BuildKeyRingArmored(readTestFile("keyring_privateKey", false))
    //
    //        // Password defined in keyring_test
    //        err = testPrivateKeyRing.UnlockWithPassphrase(testMailboxPassword)
    //        if err != nil {
    //            t.Fatal("Expected no error unlocking privateKey, got:", err)
    //        }
    //
    //        ciphertext, err := testPublicKeyRing.Encrypt(message, testPrivateKeyRing)
    //        if err != nil {
    //            t.Fatal("Expected no error when encrypting, got:", err)
    //        }
    //
    //        numKeyPackets := 0
    //        packets := packet.NewReader(bytes.NewReader(ciphertext.Data))
    //        for {
    //            var p packet.Packet
    //            if p, err = packets.Next(); err == io.EOF {
    //                err = nil
    //                break
    //            }
    //            switch p.(type) {
    //                case *packet.EncryptedKey:
    //                    numKeyPackets++
    //            }
    //        }
    //        assert.Exactly(t, 2, numKeyPackets)
    //
    //        decrypted, err := testPrivateKeyRing.Decrypt(ciphertext, testPublicKeyRing, pgp.GetUnixTime())
    //        if err != nil {
    //            t.Fatal("Expected no error when decrypting, got:", err)
    //        }
    //        assert.Exactly(t, message.GetString(), decrypted.GetString())
    //    }
    
    
    
}
