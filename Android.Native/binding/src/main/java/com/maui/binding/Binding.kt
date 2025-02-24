package com.maui.binding

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat.startActivity
import androidx.core.view.doOnAttach
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentContainerView
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ReportFragment.Companion.reportFragment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragment
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class Binding {
    private var callback: StringCallback? = null
    private var flutterView: View? = null

    fun async(activity: Activity, parameters: List<String>, callback: StringCallback) {
        this.callback = callback
        GlobalScope.launch {
            delay(1000)
            this@Binding.callback?.onResult("${parameters[0]} ${parameters[1]}")
        }
    }

    fun getFlutterView(activity: Activity): View {
        if (flutterView != null) {
            return flutterView as View
        }
        val view = FragmentContainerView(activity)
            .apply { id = View.generateViewId() }

        val flutterFragment = FlutterFragment.createDefault()

        (activity as AppCompatActivity).supportFragmentManager.beginTransaction()
            .add(view.id, flutterFragment)
            .commit()

        // Wait for fragment to be created and engine to be ready
        flutterFragment.lifecycle.addObserver(object : DefaultLifecycleObserver {
            override fun onCreate(owner: LifecycleOwner) {
                flutterFragment.flutterEngine?.let { engine ->
                    // This is crucial - without this, plugins won't work
                    GeneratedPluginRegistrant.registerWith(engine)
                }
                owner.lifecycle.removeObserver(this)
            }
        })

        flutterView = view
        return view
    }
}