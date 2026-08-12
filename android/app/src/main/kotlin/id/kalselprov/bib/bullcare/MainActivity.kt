package id.kalselprov.bib.bullcare

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.FileOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "id.kalselprov.bib.bullcare/downloads"
    private val createDocumentRequestCode = 7412

    private var pendingSaveResult: MethodChannel.Result? = null
    private var pendingSaveBytes: ByteArray? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveWithPicker" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")
                    val mimeType = call.argument<String>("mimeType")

                    if (fileName.isNullOrBlank() || bytes == null || mimeType.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "Data file tidak lengkap.", null)
                        return@setMethodCallHandler
                    }

                    if (pendingSaveResult != null) {
                        result.error(
                            "SAVE_IN_PROGRESS",
                            "Dialog penyimpanan sedang terbuka.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    pendingSaveResult = result
                    pendingSaveBytes = bytes

                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mimeType
                            putExtra(Intent.EXTRA_TITLE, fileName)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                        }

                        if (intent.resolveActivity(packageManager) == null) {
                            clearPendingSave()
                            result.error(
                                "FILE_PICKER_UNAVAILABLE",
                                "File Manager Android tidak tersedia untuk memilih lokasi penyimpanan.",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        startActivityForResult(intent, createDocumentRequestCode)
                    } catch (error: Exception) {
                        clearPendingSave()
                        result.error(
                            "OPEN_PICKER_FAILED",
                            error.message ?: "Tidak dapat membuka pemilih lokasi penyimpanan.",
                            null,
                        )
                    }
                }

                // Dipertahankan untuk kompatibilitas dengan versi sebelumnya.
                "saveToDownloads" -> saveToDownloads(call, result)

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == createDocumentRequestCode) {
            val result = pendingSaveResult
            val bytes = pendingSaveBytes

            if (result == null || bytes == null) {
                clearPendingSave()
                return
            }

            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                clearPendingSave()
                result.error(
                    "SAVE_CANCELLED",
                    "Penyimpanan file dibatalkan.",
                    null,
                )
                return
            }

            val uri = data.data!!
            try {
                contentResolver.openFileDescriptor(uri, "w")?.use { descriptor ->
                    FileOutputStream(descriptor.fileDescriptor).use { output ->
                        output.write(bytes)
                        output.flush()
                    }
                } ?: throw IllegalStateException("Tidak dapat membuka file tujuan.")

                clearPendingSave()
                result.success(uri.toString())
            } catch (error: Exception) {
                clearPendingSave()
                result.error(
                    "SAVE_FAILED",
                    error.message ?: "Gagal menyimpan file.",
                    null,
                )
            }
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun clearPendingSave() {
        pendingSaveResult = null
        pendingSaveBytes = null
    }

    private fun saveToDownloads(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(
                "UNSUPPORTED_ANDROID_VERSION",
                "MediaStore Downloads memerlukan Android 10 atau lebih baru.",
                null,
            )
            return
        }

        val fileName = call.argument<String>("fileName")
        val bytes = call.argument<ByteArray>("bytes")
        val mimeType = call.argument<String>("mimeType")

        if (fileName.isNullOrBlank() || bytes == null || mimeType.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "Data file tidak lengkap.", null)
            return
        }

        try {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/BullCare",
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Tidak dapat membuat file di folder Download/BullCare.")

            try {
                resolver.openOutputStream(uri, "w")?.use { output ->
                    output.write(bytes)
                    output.flush()
                } ?: throw IllegalStateException("Tidak dapat membuka file tujuan.")

                val completedValues = ContentValues().apply {
                    put(MediaStore.Downloads.IS_PENDING, 0)
                }
                resolver.update(uri, completedValues, null, null)
                result.success(uri.toString())
            } catch (error: Exception) {
                resolver.delete(uri, null, null)
                throw error
            }
        } catch (error: Exception) {
            result.error("SAVE_FAILED", error.message ?: "Gagal menyimpan file.", null)
        }
    }
}
