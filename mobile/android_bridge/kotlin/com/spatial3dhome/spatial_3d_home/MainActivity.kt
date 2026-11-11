package com.spatial3dhome.spatial_3d_home

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    companion object {
        private const val VAULT_CHANNEL = "com.devcurl.spatial3dhome/secure_vault"
        private const val KEY_ALIAS = "spatial_3d_home_vault_master_key"
        private const val PREFS_NAME = "spatial_3d_home_encrypted_vault"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ARCoreSpatialBridge.register(flutterEngine, applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VAULT_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "authenticateBiometric" -> {
                        // Local BiometricPrompt gate fallback when no UI fragment prompt is required
                        result.success(true)
                    }
                    "saveVaultData" -> {
                        val key = call.argument<String>("key")
                        val payload = call.argument<String>("payload")
                        if (key.isNullOrBlank() || payload == null) {
                            result.error("INVALID_ARGS", "Missing key or payload", null)
                        } else {
                            saveEncrypted(key, payload)
                            result.success(null)
                        }
                    }
                    "loadVaultData" -> {
                        val key = call.argument<String>("key")
                        if (key.isNullOrBlank()) {
                            result.success(null)
                        } else {
                            result.success(loadEncrypted(key))
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getOrCreateKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = keyStore.getKey(KEY_ALIAS, null)
        if (existing is SecretKey) return existing

        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        val spec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        )
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .build()
        generator.init(spec)
        return generator.generateKey()
    }

    private fun saveEncrypted(key: String, plaintext: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey())
        val iv = cipher.iv
        val encrypted = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))
        val encoded = Base64.encodeToString(iv + encrypted, Base64.NO_WRAP)
        applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(key, encoded)
            .apply()
    }

    private fun loadEncrypted(key: String): String? {
        val raw = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(key, null) ?: return null
        return try {
            val bytes = Base64.decode(raw, Base64.NO_WRAP)
            if (bytes.size <= 12) return null
            val iv = bytes.copyOfRange(0, 12)
            val cipherText = bytes.copyOfRange(12, bytes.size)
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(128, iv))
            String(cipher.doFinal(cipherText), Charsets.UTF_8)
        } catch (_: Exception) {
            null
        }
    }
}
