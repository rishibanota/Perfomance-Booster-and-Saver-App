package com.example.perfomance_booster.micro;

import android.app.Activity;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.BatteryManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MicroActivity extends Activity {
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private MicroDbHelper dbHelper;
    private TextView tvActiveProfile;
    private TextView tvActiveGovernor;
    private TextView tvRootStatus;
    private TextView tvBattery;
    private TextView tvCpu;

    private String currentMode = "balance";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        dbHelper = new MicroDbHelper(this);

        // Load saved mode from SQLite
        currentMode = dbHelper.getSetting("active_mode", "balance");

        // Construct lightweight programmatic UI with zero XML bloat
        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(Color.parseColor("#0B0E14"));

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(dp(20), dp(36), dp(20), dp(36));

        // App Title Header
        TextView title = new TextView(this);
        title.setText("⚡ BOOSTER MICRO");
        title.setTextSize(22);
        title.setTextColor(Color.parseColor("#00E5FF"));
        title.setTypeface(null, android.graphics.Typeface.BOLD);
        layout.addView(title);

        TextView subTitle = new TextView(this);
        subTitle.setText("Ultra-Lightweight Kernel Optimizer (<40 KB)");
        subTitle.setTextSize(12);
        subTitle.setTextColor(Color.parseColor("#94A3B8"));
        subTitle.setPadding(0, dp(2), 0, dp(16));
        layout.addView(subTitle);

        // Root Status Badge
        tvRootStatus = new TextView(this);
        tvRootStatus.setText("Checking Root Access...");
        tvRootStatus.setTextSize(12);
        tvRootStatus.setTextColor(Color.parseColor("#94A3B8"));
        tvRootStatus.setPadding(dp(12), dp(8), dp(12), dp(8));
        tvRootStatus.setBackground(createCardDrawable("#141821", "#283042"));
        layout.addView(tvRootStatus);

        addSpacing(layout, 16);

        // Active Mode Card
        LinearLayout activeCard = new LinearLayout(this);
        activeCard.setOrientation(LinearLayout.VERTICAL);
        activeCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        activeCard.setBackground(createCardDrawable("#141821", "#00E5FF"));

        TextView label = new TextView(this);
        label.setText("CURRENT ACTIVE PROFILE");
        label.setTextSize(10);
        label.setTextColor(Color.parseColor("#64748B"));
        label.setTypeface(null, android.graphics.Typeface.BOLD);
        activeCard.addView(label);

        tvActiveProfile = new TextView(this);
        tvActiveProfile.setText(currentMode.toUpperCase(Locale.ROOT));
        tvActiveProfile.setTextSize(20);
        tvActiveProfile.setTextColor(getModeColor(currentMode));
        tvActiveProfile.setTypeface(null, android.graphics.Typeface.BOLD);
        activeCard.addView(tvActiveProfile);

        tvActiveGovernor = new TextView(this);
        tvActiveGovernor.setText("Governor: " + getGovernorForMode(currentMode) + " (Saved in SQLite)");
        tvActiveGovernor.setTextSize(12);
        tvActiveGovernor.setTextColor(Color.parseColor("#94A3B8"));
        activeCard.addView(tvActiveGovernor);

        layout.addView(activeCard);

        addSpacing(layout, 20);

        // Section Title: Profiles
        TextView sectionTitle = new TextView(this);
        sectionTitle.setText("SELECT PROFILE (3 MODES)");
        sectionTitle.setTextSize(11);
        sectionTitle.setTextColor(Color.parseColor("#64748B"));
        sectionTitle.setTypeface(null, android.graphics.Typeface.BOLD);
        sectionTitle.setPadding(0, 0, 0, dp(10));
        layout.addView(sectionTitle);

        // Button 1: Performance Mode
        Button btnPerf = createButton("🚀 PERFORMANCE MODE", "#FF5252", new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                applyMode("performance");
            }
        });
        layout.addView(btnPerf);
        addSpacing(layout, 12);

        // Button 2: Balance Mode
        Button btnBalance = createButton("⚖️ BALANCE MODE (schedutil)", "#00E5FF", new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                applyMode("balance");
            }
        });
        layout.addView(btnBalance);
        addSpacing(layout, 12);

        // Button 3: Saver Mode
        Button btnSaver = createButton("🍃 SAVER MODE (powersave)", "#00E676", new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                applyMode("saver");
            }
        });
        layout.addView(btnSaver);
        addSpacing(layout, 20);

        // Hardware Monitor Card
        LinearLayout monitorCard = new LinearLayout(this);
        monitorCard.setOrientation(LinearLayout.VERTICAL);
        monitorCard.setPadding(dp(16), dp(14), dp(16), dp(14));
        monitorCard.setBackground(createCardDrawable("#141821", "#283042"));

        TextView monitorTitle = new TextView(this);
        monitorTitle.setText("HARDWARE MONITOR");
        monitorTitle.setTextSize(12);
        monitorTitle.setTextColor(Color.parseColor("#00E5FF"));
        monitorTitle.setTypeface(null, android.graphics.Typeface.BOLD);
        monitorCard.addView(monitorTitle);

        tvBattery = new TextView(this);
        tvBattery.setText("Battery: Loading...");
        tvBattery.setTextSize(13);
        tvBattery.setTextColor(Color.WHITE);
        tvBattery.setPadding(0, dp(6), 0, 0);
        monitorCard.addView(tvBattery);

        tvCpu = new TextView(this);
        tvCpu.setText("CPU Scaling: Loading...");
        tvCpu.setTextSize(13);
        tvCpu.setTextColor(Color.WHITE);
        tvCpu.setPadding(0, dp(4), 0, 0);
        monitorCard.addView(tvCpu);

        layout.addView(monitorCard);

        addSpacing(layout, 16);

        // Quick App Killer Button
        Button btnKill = createButton("🧹 STOP BACKGROUND SOCIAL APPS", "#283042", new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                killBackgroundApps();
            }
        });
        btnKill.setTextColor(Color.parseColor("#F1F5F9"));
        layout.addView(btnKill);

        scrollView.addView(layout);
        setContentView(scrollView);

        // Initial background tasks
        checkRoot();
        refreshMetrics();
    }

    private void applyMode(final String mode) {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                final String gov = getGovernorForMode(mode);
                final String time = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(new Date());

                // 1. If saver mode, kill apps
                if ("saver".equalsIgnoreCase(mode)) {
                    executeSu("am force-stop com.whatsapp");
                    executeSu("am force-stop com.facebook.katana");
                    executeSu("am force-stop org.telegram.messenger");
                    executeSu("am force-stop com.instagram.android");
                }

                // 2. Set CPU governors for cpu0, cpu7, and all policy nodes
                StringBuilder sb = new StringBuilder();
                sb.append("echo ").append(gov).append(" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null; ");
                sb.append("echo ").append(gov).append(" > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor 2>/dev/null; ");
                sb.append("for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo ").append(gov).append(" > \"$f\" 2>/dev/null; done; ");
                sb.append("for p in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor; do echo ").append(gov).append(" > \"$p\" 2>/dev/null; done");
                executeSu(sb.toString());

                // 3. Persist in local SQLite
                dbHelper.setSetting("active_mode", mode);
                dbHelper.insertHistory(mode, gov, getBatteryString(), time);

                currentMode = mode;

                mainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        tvActiveProfile.setText(mode.toUpperCase(Locale.ROOT));
                        tvActiveProfile.setTextColor(getModeColor(mode));
                        tvActiveGovernor.setText("Governor: " + gov + " (Saved in SQLite)");
                        Toast.makeText(MicroActivity.this, "Activated " + mode.toUpperCase(Locale.ROOT) + " (" + gov + ")", Toast.LENGTH_SHORT).show();
                        refreshMetrics();
                    }
                });
            }
        });
    }

    private void killBackgroundApps() {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                executeSu("am force-stop com.whatsapp");
                executeSu("am force-stop com.facebook.katana");
                executeSu("am force-stop org.telegram.messenger");
                executeSu("am force-stop com.instagram.android");

                mainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        Toast.makeText(MicroActivity.this, "Background apps force-stopped", Toast.LENGTH_SHORT).show();
                    }
                });
            }
        });
    }

    private void checkRoot() {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                String res = executeSu("id");
                final boolean granted = res != null && res.contains("uid=0");

                mainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (granted) {
                            tvRootStatus.setText("✓ Root Access Granted (uid=0)");
                            tvRootStatus.setTextColor(Color.parseColor("#00E676"));
                        } else {
                            tvRootStatus.setText("✗ Root Denied or SU Binary Missing");
                            tvRootStatus.setTextColor(Color.parseColor("#FF5252"));
                        }
                    }
                });
            }
        });
    }

    private void refreshMetrics() {
        executor.execute(new Runnable() {
            @Override
            public void run() {
                final String batStr = getBatteryString();
                final String cpu0Gov = executeSu("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor").trim();
                final String cpu7Gov = executeSu("cat /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor").trim();

                mainHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        tvBattery.setText("Battery: " + batStr);
                        tvCpu.setText("CPU0: " + (cpu0Gov.isEmpty() ? "unknown" : cpu0Gov) +
                                " | CPU7: " + (cpu7Gov.isEmpty() ? "unknown" : cpu7Gov));
                    }
                });
            }
        });
    }

    private String getBatteryString() {
        try {
            Intent intent = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
            if (intent != null) {
                int level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
                int scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1);
                int pct = (level * 100) / scale;
                int temp = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0);
                return pct + "% (" + (temp / 10.0) + "°C)";
            }
        } catch (Exception ignored) {}
        return "100%";
    }

    private String executeSu(String cmd) {
        StringBuilder output = new StringBuilder();
        try {
            Process p = Runtime.getRuntime().exec("su");
            DataOutputStream os = new DataOutputStream(p.getOutputStream());
            os.writeBytes(cmd + "\n");
            os.writeBytes("exit\n");
            os.flush();
            BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }
            p.waitFor();
        } catch (Exception e) {
            return "";
        }
        return output.toString();
    }

    private String getGovernorForMode(String mode) {
        if ("performance".equalsIgnoreCase(mode)) return "performance";
        if ("saver".equalsIgnoreCase(mode)) return "powersave";
        return "schedutil";
    }

    private int getModeColor(String mode) {
        if ("performance".equalsIgnoreCase(mode)) return Color.parseColor("#FF5252");
        if ("saver".equalsIgnoreCase(mode)) return Color.parseColor("#00E676");
        return Color.parseColor("#00E5FF");
    }

    private Button createButton(String text, String colorHex, View.OnClickListener listener) {
        Button btn = new Button(this);
        btn.setText(text);
        btn.setTextColor(Color.BLACK);
        btn.setTextSize(13);
        btn.setTypeface(null, android.graphics.Typeface.BOLD);
        btn.setPadding(dp(16), dp(14), dp(16), dp(14));
        btn.setGravity(Gravity.CENTER);
        btn.setBackground(createCardDrawable(colorHex, colorHex));
        btn.setOnClickListener(listener);
        return btn;
    }

    private GradientDrawable createCardDrawable(String bgColorHex, String strokeColorHex) {
        GradientDrawable gd = new GradientDrawable();
        gd.setColor(Color.parseColor(bgColorHex));
        gd.setCornerRadius(dp(14));
        gd.setStroke(dp(1), Color.parseColor(strokeColorHex));
        return gd;
    }

    private void addSpacing(LinearLayout layout, int dp) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(dp)));
        layout.addView(v);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }

    // Local SQLite database helper (<5 KB footprint)
    static class MicroDbHelper extends SQLiteOpenHelper {
        public MicroDbHelper(Context context) {
            super(context, "performance_booster_micro.db", null, 1);
        }

        @Override
        public void onCreate(SQLiteDatabase db) {
            db.execSQL("CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT);");
            db.execSQL("CREATE TABLE IF NOT EXISTS mode_history (id INTEGER PRIMARY KEY AUTOINCREMENT, mode TEXT, governor TEXT, battery TEXT, timestamp TEXT);");
            ContentValues cv = new ContentValues();
            cv.put("key", "active_mode");
            cv.put("value", "balance");
            db.insertWithOnConflict("settings", null, cv, SQLiteDatabase.CONFLICT_IGNORE);
        }

        @Override
        public void onUpgrade(SQLiteDatabase db, int oldV, int newV) {}

        public String getSetting(String key, String def) {
            SQLiteDatabase db = getReadableDatabase();
            Cursor c = db.query("settings", new String[]{"value"}, "key = ?", new String[]{key}, null, null, null);
            if (c != null) {
                try {
                    if (c.moveToFirst()) return c.getString(0);
                } finally {
                    c.close();
                }
            }
            return def;
        }

        public void setSetting(String key, String value) {
            SQLiteDatabase db = getWritableDatabase();
            ContentValues cv = new ContentValues();
            cv.put("key", key);
            cv.put("value", value);
            db.insertWithOnConflict("settings", null, cv, SQLiteDatabase.CONFLICT_REPLACE);
        }

        public void insertHistory(String mode, String gov, String bat, String time) {
            SQLiteDatabase db = getWritableDatabase();
            ContentValues cv = new ContentValues();
            cv.put("mode", mode);
            cv.put("governor", gov);
            cv.put("battery", bat);
            cv.put("timestamp", time);
            db.insert("mode_history", null, cv);
        }
    }
}
