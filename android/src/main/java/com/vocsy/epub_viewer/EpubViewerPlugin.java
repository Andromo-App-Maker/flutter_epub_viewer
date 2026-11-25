package com.vocsy.epub_viewer;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import java.util.Map;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

import androidx.annotation.NonNull;

import com.folioreader.model.locators.ReadLocator;

/**
 * EpubReaderPlugin
 */
public class EpubViewerPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware {

    private Reader reader;
    private ReaderConfig config;
    private MethodChannel channel;
    static private Activity activity;
    static private Context context;
    static BinaryMessenger messenger;
    static private EventChannel eventChannel;
    static private EventChannel.EventSink sink;
    private static final String channelName = "vocsy_epub_viewer";

    /**
     * Single handler for the "page" channel. A second {@link EventChannel} on the same
     * name replaces the active stream, and the next cancel fails with
     * "No active stream to cancel".
     */
    private static final EventChannel.StreamHandler pageStreamHandler = new EventChannel.StreamHandler() {
        @Override
        public void onListen(Object arguments, EventChannel.EventSink eventSink) {
            sink = eventSink;
        }

        @Override
        public void onCancel(Object arguments) {
            sink = null;
        }
    };

    // Removed legacy v1 embedding Registrar-based registration.

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        messenger = binding.getBinaryMessenger();
        context = binding.getApplicationContext();
        if (eventChannel != null) {
            eventChannel.setStreamHandler(null);
        }
        eventChannel = new EventChannel(messenger, "page");
        eventChannel.setStreamHandler(pageStreamHandler);
        channel = new MethodChannel(messenger, channelName);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        sink = null;
        if (eventChannel != null) {
            eventChannel.setStreamHandler(null);
            eventChannel = null;
        }
        if (channel != null) {
            channel.setMethodCallHandler(null);
            channel = null;
        }
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
        activity = activityPluginBinding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding activityPluginBinding) {

    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {

        if (call.method.equals("setConfig")) {
            Map<String, Object> arguments = (Map<String, Object>) call.arguments;
            String identifier = arguments.get("identifier").toString();
            String themeColor = arguments.get("themeColor").toString();
            String scrollDirection = arguments.get("scrollDirection").toString();
            Boolean nightMode = Boolean.parseBoolean(arguments.get("nightMode").toString());
            Boolean allowSharing = Boolean.parseBoolean(arguments.get("allowSharing").toString());
            Boolean enableTts = Boolean.parseBoolean(arguments.get("enableTts").toString());
            config = new ReaderConfig(context, identifier, themeColor,
                    scrollDirection, allowSharing, enableTts, nightMode);

        } else if (call.method.equals("open")) {

            Map<String, Object> arguments = (Map<String, Object>) call.arguments;
            String bookPath = arguments.get("bookPath").toString();
            String lastLocation = arguments.get("lastLocation").toString();

            Log.i("opening", "In open function");

            if (sink == null) {
                Log.i("sink status", "sink is empty");
            }
            reader = new Reader(context, messenger, config, sink);
            reader.open(bookPath, lastLocation);

        } else if (call.method.equals("close")) {
            reader.close();
        } else if (call.method.equals("setChannel")) {
            // Registered once in onAttachedToEngine. Creating another EventChannel
            // here drops the active listen, so cancel throws.
            result.success(null);
        } else {
            result.notImplemented();
        }
    }
}
