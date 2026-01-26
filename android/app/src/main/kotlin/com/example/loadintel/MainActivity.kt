package com.vitomein.loadintel

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "com.vitomein.loadintel/export"
  private val pickDirectoryRequestCode = 5010
  private var pendingResult: MethodChannel.Result? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "pickDirectory" -> handlePickDirectory(result)
          "writeFile" -> handleWriteFile(call, result)
          else -> result.notImplemented()
        }
      }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    if (requestCode == pickDirectoryRequestCode) {
      val result = pendingResult
      pendingResult = null
      if (result == null) {
        super.onActivityResult(requestCode, resultCode, data)
        return
      }
      if (resultCode != Activity.RESULT_OK || data?.data == null) {
        result.success(null)
        return
      }
      val uri = data.data!!
      val takeFlags = data.flags and
        (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
      contentResolver.takePersistableUriPermission(uri, takeFlags)
      result.success(uri.toString())
      return
    }
    super.onActivityResult(requestCode, resultCode, data)
  }

  private fun handlePickDirectory(result: MethodChannel.Result) {
    if (pendingResult != null) {
      result.error("PENDING", "Directory picker already active", null)
      return
    }
    pendingResult = result
    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
      addFlags(
        Intent.FLAG_GRANT_READ_URI_PERMISSION or
          Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
          Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
          Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
      )
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val initialUri = initialDocumentsUri()
        if (initialUri != null) {
          putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
        }
      }
    }
    startActivityForResult(intent, pickDirectoryRequestCode)
  }

  private fun handleWriteFile(call: MethodCall, result: MethodChannel.Result) {
    try {
      val treeUriString = call.argument<String>("treeUri")
      val fileName = call.argument<String>("fileName")
      val mimeType = call.argument<String>("mimeType")
      val bytes = call.argument<ByteArray>("bytes")
      val subDir = call.argument<String>("subDir")

      if (treeUriString == null || fileName == null || mimeType == null || bytes == null) {
        result.error("INVALID_ARGS", "Missing arguments", null)
        return
      }

      val treeUri = Uri.parse(treeUriString)
      val targetDirUri = if (!subDir.isNullOrBlank()) {
        ensureSubdirectory(treeUri, subDir)
      } else {
        documentUriForTree(treeUri)
      }

      val createdUri = DocumentsContract.createDocument(
        contentResolver,
        targetDirUri,
        mimeType,
        fileName
      )
      if (createdUri == null) {
        result.error("CREATE_FAILED", "Unable to create file", null)
        return
      }

      contentResolver.openOutputStream(createdUri, "w")?.use { stream ->
        stream.write(bytes)
      } ?: run {
        result.error("WRITE_FAILED", "Unable to open output stream", null)
        return
      }

      result.success(createdUri.toString())
    } catch (e: Exception) {
      result.error("WRITE_FAILED", e.message, null)
    }
  }

  private fun ensureSubdirectory(treeUri: Uri, name: String): Uri {
    val treeDocId = DocumentsContract.getTreeDocumentId(treeUri)
    val treeDocUri = documentUriForTree(treeUri)
    val treeName = documentDisplayName(treeDocUri)
    if (treeName == name) {
      return treeDocUri
    }
    val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, treeDocId)
    val projection = arrayOf(
      DocumentsContract.Document.COLUMN_DOCUMENT_ID,
      DocumentsContract.Document.COLUMN_DISPLAY_NAME,
      DocumentsContract.Document.COLUMN_MIME_TYPE
    )
    contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
      val idIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
      val nameIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
      val mimeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
      while (cursor.moveToNext()) {
        val displayName = cursor.getString(nameIndex)
        val mimeType = cursor.getString(mimeIndex)
        if (displayName == name && mimeType == DocumentsContract.Document.MIME_TYPE_DIR) {
          val docId = cursor.getString(idIndex)
          return DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
        }
      }
    }

    val parentUri = treeDocUri
    val created = DocumentsContract.createDocument(
      contentResolver,
      parentUri,
      DocumentsContract.Document.MIME_TYPE_DIR,
      name
    )
    return created ?: parentUri
  }

  private fun documentUriForTree(treeUri: Uri): Uri {
    val docId = DocumentsContract.getTreeDocumentId(treeUri)
    return DocumentsContract.buildDocumentUriUsingTree(treeUri, docId)
  }

  private fun documentDisplayName(documentUri: Uri): String? {
    val projection = arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
    contentResolver.query(documentUri, projection, null, null, null)?.use { cursor ->
      if (cursor.moveToFirst()) {
        return cursor.getString(0)
      }
    }
    return null
  }

  private fun initialDocumentsUri(): Uri? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Uri.parse("content://com.android.externalstorage.documents/document/primary:Documents")
    } else {
      null
    }
  }
}
