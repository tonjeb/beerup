package com.gotonje.beerup;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        onNewIntent(getIntent());

        final WebView webview = new WebView(this);
        setContentView(webview);
        webview.loadUrl("http://beerup.gotonje.com/");

        webview.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {

                if (url.equals("http://beerup.gotonje.com/display"))
                {
                    Log.d("Konge", url);
                    Intent unityView = new Intent(MainActivity.this, UnityPlayerNativeActivity.class);
                    MainActivity.this.startActivity(unityView);
                    return true;
                }
                else
                {
                    view.loadUrl(url);
                    return false;
                }
            }
        });
    }
}
