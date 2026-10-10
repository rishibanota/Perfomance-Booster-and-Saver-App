package com.example.perfomance_booster_and_saver_app

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.File
import java.io.InputStreamReader
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.perfomance_booster_and_saver_app/root"
    private val executor = Executors.newCachedThreadPool()
    private val mainHandler = Handler(Looper.getMainLooper())
    private lateinit var dbHelper: PerformanceDbHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        dbHelper = PerformanceDbHelper(context)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            executor.execute {
                handleMethodCall(call, result)
            }
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "checkRoot" -> {
                    val rootStatus = checkRootInternal()
                    postSuccess(result, rootStatus)
                }
                "requestRoot" -> {
                    val rootResult = requestRootInternal()
                    postSuccess(result, rootResult)
                }
                "executeCommand" -> {
                    val command = call.argument<String>("command") ?: ""
                    val execResult = executeSuCommand(command)
                    postSuccess(result, mapOf(
                        "success" to execResult.success,
                        "stdout" to execResult.stdout,
                        "stderr" to execResult.stderr,
                        "exitCode" to execResult.exitCode
                    ))
                }
                "applyMode" -> {
                    val mode = call.argument<String>("mode") ?: "balance"
                    val killApps = call.argument<Boolean>("killApps") ?: false
                    val disableNetwork = call.argument<Boolean>("disableNetwork") ?: false
                    val customApps = call.argument<List<String>>("customApps") ?: listOf(
                        "com.whatsapp",
                        "com.facebook.katana",
                        "org.telegram.messenger",
                        "com.instagram.android"
                    )

                    val applyResult = applyModeInternal(mode, killApps, disableNetwork, customApps)
                    postSuccess(result, applyResult)
                }
                "getBatteryInfo" -> {
                    val batteryInfo = getBatteryInfoInternal()
                    postSuccess(result, batteryInfo)
                }
                "getCpuInfo" -> {
                    val cpuInfo = getCpuInfoInternal()
                    postSuccess(result, cpuInfo)
                }
                "forceStopApps" -> {
                    val apps = call.argument<List<String>>("packages") ?: emptyList()
                    val stopResult = forceStopAppsInternal(apps)
                    postSuccess(result, stopResult)
                }
                // SQLite Local DB methods
                "dbGetSetting" -> {
                    val key = call.argument<String>("key") ?: ""
                    val value = dbHelper.getSetting(key)
                    postSuccess(result, value)
                }
                "dbSetSetting" -> {
                    val key = call.argument<String>("key") ?: ""
                    val value = call.argument<String>("value") ?: ""
                    dbHelper.setSetting(key, value)
                    postSuccess(result, true)
                }
                "dbGetAllSettings" -> {
                    val settings = dbHelper.getAllSettings()
                    postSuccess(result, settings)
                }
                "dbInsertHistory" -> {
                    val mode = call.argument<String>("mode") ?: ""
                    val governor = call.argument<String>("governor") ?: ""
                    val battery = call.argument<String>("battery") ?: ""
                    val timestamp = call.argument<String>("timestamp") ?: SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
                    val success = if (call.argument<Boolean>("success") == true) 1 else 0
                    val notes = call.argument<String>("notes") ?: ""
                    val id = dbHelper.insertHistory(mode, governor, battery, timestamp, success, notes)
                    postSuccess(result, id)
                }
                "dbGetHistory" -> {
                    val limit = call.argument<Int>("limit") ?: 50
                    val history = dbHelper.getHistory(limit)
                    postSuccess(result, history)
                }
                "dbClearHistory" -> {
                    dbHelper.clearHistory()
                    postSuccess(result, true)
                }
                else -> {
                    postNotImplemented(result)
                }
            }
        } catch (e: Exception) {
            postError(result, "UNHANDLED_EXCEPTION", e.message ?: "Unknown error occurred", null)
        }
    }

    private fun postSuccess(result: MethodChannel.Result, data: Any?) {
        mainHandler.post { result.success(data) }
    }

    private fun postError(result: MethodChannel.Result, code: String, msg: String, details: Any?) {
        mainHandler.post { result.error(code, msg, details) }
    }

    private fun postNotImplemented(result: MethodChannel.Result) {
        mainHandler.post { result.notImplemented() }
    }

    data class ShellResult(
        val success: Boolean,
        val stdout: String,
        val stderr: String,
        val exitCode: Int
    )

    private fun executeSuCommand(command: String): ShellResult {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", command))
            val stdout = BufferedReader(InputStreamReader(process.inputStream)).readText()
            val stderr = BufferedReader(InputStreamReader(process.errorStream)).readText()
            val exitCode = process.waitFor()
            ShellResult(exitCode == 0, stdout.trim(), stderr.trim(), exitCode)
        } catch (e: Exception) {
            // Fallback via piping to su standard input
            try {
                val process = Runtime.getRuntime().exec("su")
                val os = DataOutputStream(process.outputStream)
                os.writeBytes(command + "\n")
                os.writeBytes("exit\n")
                os.flush()
                val stdout = BufferedReader(InputStreamReader(process.inputStream)).readText()
                val stderr = BufferedReader(InputStreamReader(process.errorStream)).readText()
                val exitCode = process.waitFor()
                ShellResult(exitCode == 0, stdout.trim(), stderr.trim(), exitCode)
            } catch (fallbackEx: Exception) {
                ShellResult(false, "", e.message ?: fallbackEx.message ?: "Failed to execute su", -1)
            }
        }
    }

    private fun checkRootInternal(): Map<String, Any> {
        val suPaths = arrayOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/data/local/su",
            "/su/bin/su",
            "/data/adb/ksu/bin/su",
            "/data/adb/ap/bin/su"
        )
        val suFound = suPaths.any { File(it).exists() } || canExecuteWhichSu()

        val idCheck = executeSuCommand("id")
        val isGranted = idCheck.success && idCheck.stdout.contains("uid=0")

        return mapOf(
            "available" to (suFound || isGranted),
            "granted" to isGranted,
            "details" to if (isGranted) "Root access granted (uid=0)" else if (suFound) "SU binary found, root prompt needed" else "SU binary not found"
        )
    }

    private fun canExecuteWhichSu(): Boolean {
        return try {
            val p = Runtime.getRuntime().exec(arrayOf("which", "su"))
            p.waitFor() == 0
        } catch (_: Exception) {
            false
        }
    }

    private fun requestRootInternal(): Map<String, Any> {
        val result = executeSuCommand("id")
        val isGranted = result.success && result.stdout.contains("uid=0")
        return mapOf(
            "granted" to isGranted,
            "stdout" to result.stdout,
            "stderr" to result.stderr,
            "exitCode" to result.exitCode
        )
    }

    private fun applyModeInternal(
        mode: String,
        killApps: Boolean,
        disableNetwork: Boolean,
        customApps: List<String>
    ): Map<String, Any> {
        val targetGovernor = when (mode.lowercase(Locale.ROOT)) {
            "performance" -> "performance"
            "saver" -> "powersave"
            else -> "schedutil"
        }

        val logs = mutableListOf<String>()
        val timestamp = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date())
        var overallSuccess = true

        // 1. Force stop background apps if saver mode and option enabled
        if (mode.lowercase(Locale.ROOT) == "saver" && killApps && customApps.isNotEmpty()) {
            for (app in customApps) {
                val stopRes = executeSuCommand("am force-stop $app")
                if (stopRes.success) {
                    logs.add("Force stopped: $app")
                } else {
                    logs.add("Warning stopping $app: ${stopRes.stderr}")
                }
            }
        }

        // 2. Set CPU scaling governors
        // Targets both cpu0 & cpu7 explicitly as in sample scripts,
        // as well as all available cpu*/cpufreq and policy*/cpufreq nodes dynamically.
        val govScript = StringBuilder()
        govScript.append("echo $targetGovernor > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; ")
        govScript.append("echo $targetGovernor > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor 2>/dev/null; ")
        govScript.append("for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do [ -f \"\$f\" ] && echo $targetGovernor > \"\$f\" 2>/dev/null; done; ")
        govScript.append("for p in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor; do [ -f \"\$p\" ] && echo $targetGovernor > \"\$p\" 2>/dev/null; done; ")
        govScript.append("echo 'GOVERNOR_SET_DONE'")

        val govRes = executeSuCommand(govScript.toString())
        if (govRes.success || govRes.stdout.contains("GOVERNOR_SET_DONE")) {
            logs.add("Successfully applied '$targetGovernor' governor to CPU cores")
        } else {
            overallSuccess = false
            logs.add("Governor setting returned: ${govRes.stderr.ifEmpty { govRes.stdout }}")
        }

        // 3. Network controls if saver and disableNetwork enabled
        if (mode.lowercase(Locale.ROOT) == "saver" && disableNetwork) {
            val netWifiRes = executeSuCommand("svc wifi disable")
            val netDataRes = executeSuCommand("svc data disable")
            logs.add("Disabled WiFi: ${if (netWifiRes.success) "OK" else netWifiRes.stderr}")
            logs.add("Disabled Mobile Data: ${if (netDataRes.success) "OK" else netDataRes.stderr}")
        }

        // 4. Read battery status
        val batteryInfo = getBatteryInfoInternal()
        val batteryLevel = "${batteryInfo["level"]}%"

        // 5. Persist to SQLite DB
        dbHelper.setSetting("active_mode", mode.lowercase(Locale.ROOT))
        dbHelper.setSetting("last_governor", targetGovernor)
        dbHelper.setSetting("last_applied_time", timestamp)
        dbHelper.insertHistory(
            mode = mode.lowercase(Locale.ROOT),
            governor = targetGovernor,
            battery = batteryLevel,
            timestamp = timestamp,
            success = if (overallSuccess) 1 else 0,
            notes = logs.joinToString("; ")
        )

        return mapOf(
            "success" to overallSuccess,
            "mode" to mode.lowercase(Locale.ROOT),
            "governor" to targetGovernor,
            "battery" to batteryLevel,
            "timestamp" to timestamp,
            "logs" to logs
        )
    }

    private fun forceStopAppsInternal(apps: List<String>): Map<String, Any> {
        val stopped = mutableListOf<String>()
        for (app in apps) {
            val res = executeSuCommand("am force-stop $app")
            if (res.success) {
                stopped.add(app)
            }
        }
        return mapOf(
            "success" to stopped.isNotEmpty(),
            "stopped" to stopped
        )
    }

    private fun getBatteryInfoInternal(): Map<String, Any> {
        var level = -1
        var temp = 0.0
        var status = "Unknown"
        var health = "Good"
        var voltage = 0
        var isCharging = false

        // Try reading via dumpsys battery using root
        val dumpsys = executeSuCommand("dumpsys battery")
        if (dumpsys.success && dumpsys.stdout.isNotEmpty()) {
            val lines = dumpsys.stdout.split("\n")
            for (line in lines) {
                val trimmed = line.trim()
                if (trimmed.startsWith("level:")) {
                    level = trimmed.substringAfter(":").trim().toIntOrNull() ?: level
                } else if (trimmed.startsWith("temperature:")) {
                    val rawTemp = trimmed.substringAfter(":").trim().toDoubleOrNull() ?: 0.0
                    temp = rawTemp / 10.0
                } else if (trimmed.startsWith("voltage:")) {
                    voltage = trimmed.substringAfter(":").trim().toIntOrNull() ?: 0
                } else if (trimmed.startsWith("status:")) {
                    val statusInt = trimmed.substringAfter(":").trim().toIntOrNull() ?: 1
                    status = when (statusInt) {
                        BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
                        BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
                        BatteryManager.BATTERY_STATUS_FULL -> "Full"
                        BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not Charging"
                        else -> "Unknown"
                    }
                    isCharging = statusInt == BatteryManager.BATTERY_STATUS_CHARGING
                } else if (trimmed.startsWith("health:")) {
                    val healthInt = trimmed.substringAfter(":").trim().toIntOrNull() ?: 1
                    health = when (healthInt) {
                        BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
                        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
                        BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
                        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
                        else -> "Normal"
                    }
                }
            }
        }

        // Fallback to standard BatteryManager if dumpsys failed
        if (level == -1) {
            try {
                val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                if (intent != null) {
                    val rawLevel = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                    val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                    if (rawLevel != -1 && scale > 0) {
                        level = (rawLevel * 100) / scale
                    }
                    val statusInt = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
                    isCharging = statusInt == BatteryManager.BATTERY_STATUS_CHARGING || statusInt == BatteryManager.BATTERY_STATUS_FULL
                    status = if (isCharging) "Charging" else "Discharging"
                    val rawTemp = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
                    temp = rawTemp / 10.0
                    voltage = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0)
                }
            } catch (_: Exception) {}
        }

        return mapOf(
            "level" to (if (level >= 0) level else 100),
            "temperature" to temp,
            "status" to status,
            "health" to health,
            "voltage" to voltage,
            "isCharging" to isCharging
        )
    }

    private fun getCpuInfoInternal(): Map<String, Any> {
        val coreCount = Runtime.getRuntime().availableProcessors()
        val governors = mutableMapOf<String, String>()
        val availableGovernors = mutableListOf<String>()

        // Read governors for each CPU core
        val govCheck = executeSuCommand("for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do echo \"\$(basename \$(dirname \$(dirname \$f))): \$(cat \$f 2>/dev/null)\"; done")
        if (govCheck.success && govCheck.stdout.isNotEmpty()) {
            govCheck.stdout.split("\n").forEach { line ->
                val parts = line.split(":")
                if (parts.size == 2) {
                    val core = parts[0].trim()
                    val gov = parts[1].trim()
                    if (core.isNotEmpty() && gov.isNotEmpty()) {
                        governors[core] = gov
                    }
                }
            }
        }

        // Read available governors from cpu0
        val availCheck = executeSuCommand("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors")
        if (availCheck.success && availCheck.stdout.isNotEmpty()) {
            availCheck.stdout.split("\\s+".toRegex()).forEach { g ->
                val trimmed = g.trim()
                if (trimmed.isNotEmpty() && !availableGovernors.contains(trimmed)) {
                    availableGovernors.add(trimmed)
                }
            }
        }

        if (availableGovernors.isEmpty()) {
            availableGovernors.addAll(listOf("performance", "schedutil", "powersave"))
        }

        return mapOf(
            "coreCount" to coreCount,
            "governors" to governors,
            "availableGovernors" to availableGovernors
        )
    }
}

class PerformanceDbHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {
    companion object {
        const val DATABASE_NAME = "performance_booster.db"
        const val DATABASE_VERSION = 1

        const val TABLE_SETTINGS = "settings"
        const val COL_SETTING_KEY = "key"
        const val COL_SETTING_VALUE = "value"

        const val TABLE_HISTORY = "mode_history"
        const val COL_HIST_ID = "id"
        const val COL_HIST_MODE = "mode"
        const val COL_HIST_GOVERNOR = "governor"
        const val COL_HIST_BATTERY = "battery_level"
        const val COL_HIST_TIMESTAMP = "timestamp"
        const val COL_HIST_SUCCESS = "success"
        const val COL_HIST_NOTES = "notes"
    }

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_SETTINGS (
                $COL_SETTING_KEY TEXT PRIMARY KEY,
                $COL_SETTING_VALUE TEXT
            )
        """.trimIndent())

        db.execSQL("""
            CREATE TABLE IF NOT EXISTS $TABLE_HISTORY (
                $COL_HIST_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COL_HIST_MODE TEXT,
                $COL_HIST_GOVERNOR TEXT,
                $COL_HIST_BATTERY TEXT,
                $COL_HIST_TIMESTAMP TEXT,
                $COL_HIST_SUCCESS INTEGER,
                $COL_HIST_NOTES TEXT
            )
        """.trimIndent())

        // Insert default initial option
        val initialValues = ContentValues().apply {
            put(COL_SETTING_KEY, "active_mode")
            put(COL_SETTING_VALUE, "balance")
        }
        db.insertWithOnConflict(TABLE_SETTINGS, null, initialValues, SQLiteDatabase.CONFLICT_IGNORE)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_SETTINGS")
        db.execSQL("DROP TABLE IF EXISTS $TABLE_HISTORY")
        onCreate(db)
    }

    fun getSetting(key: String): String? {
        val db = readableDatabase
        val cursor = db.query(TABLE_SETTINGS, arrayOf(COL_SETTING_VALUE), "$COL_SETTING_KEY = ?", arrayOf(key), null, null, null)
        return cursor.use {
            if (it.moveToFirst()) it.getString(0) else null
        }
    }

    fun setSetting(key: String, value: String) {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COL_SETTING_KEY, key)
            put(COL_SETTING_VALUE, value)
        }
        db.insertWithOnConflict(TABLE_SETTINGS, null, values, SQLiteDatabase.CONFLICT_REPLACE)
    }

    fun getAllSettings(): Map<String, String> {
        val result = mutableMapOf<String, String>()
        val db = readableDatabase
        val cursor = db.query(TABLE_SETTINGS, arrayOf(COL_SETTING_KEY, COL_SETTING_VALUE), null, null, null, null, null)
        cursor.use {
            while (it.moveToNext()) {
                result[it.getString(0)] = it.getString(1)
            }
        }
        return result
    }

    fun insertHistory(mode: String, governor: String, battery: String, timestamp: String, success: Int, notes: String): Long {
        val db = writableDatabase
        val values = ContentValues().apply {
            put(COL_HIST_MODE, mode)
            put(COL_HIST_GOVERNOR, governor)
            put(COL_HIST_BATTERY, battery)
            put(COL_HIST_TIMESTAMP, timestamp)
            put(COL_HIST_SUCCESS, success)
            put(COL_HIST_NOTES, notes)
        }
        return db.insert(TABLE_HISTORY, null, values)
    }

    fun getHistory(limit: Int): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val db = readableDatabase
        val cursor = db.query(TABLE_HISTORY, null, null, null, null, null, "$COL_HIST_ID DESC", limit.toString())
        cursor.use {
            val idIdx = it.getColumnIndex(COL_HIST_ID)
            val modeIdx = it.getColumnIndex(COL_HIST_MODE)
            val govIdx = it.getColumnIndex(COL_HIST_GOVERNOR)
            val batIdx = it.getColumnIndex(COL_HIST_BATTERY)
            val timeIdx = it.getColumnIndex(COL_HIST_TIMESTAMP)
            val succIdx = it.getColumnIndex(COL_HIST_SUCCESS)
            val notesIdx = it.getColumnIndex(COL_HIST_NOTES)

            while (it.moveToNext()) {
                val item = mutableMapOf<String, Any>()
                if (idIdx != -1) item["id"] = it.getLong(idIdx)
                if (modeIdx != -1) item["mode"] = it.getString(modeIdx)
                if (govIdx != -1) item["governor"] = it.getString(govIdx)
                if (batIdx != -1) item["battery"] = it.getString(batIdx)
                if (timeIdx != -1) item["timestamp"] = it.getString(timeIdx)
                if (succIdx != -1) item["success"] = it.getInt(succIdx) == 1
                if (notesIdx != -1) item["notes"] = it.getString(notesIdx) ?: ""
                list.add(item)
            }
        }
        return list
    }

    fun clearHistory() {
        val db = writableDatabase
        db.delete(TABLE_HISTORY, null, null)
    }
}
