package expo.modules.mymodule

import android.app.Activity.RESULT_OK
import android.content.Intent
import android.speech.RecognizerIntent
import android.widget.Toast
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.net.URL
import java.util.Locale

class MyModule : Module() {

    val REQUEST_CODE_SPEECH_INPUT = 100

    private val context
        get() = requireNotNull(appContext.reactContext)

    private val activity
        get() = requireNotNull(appContext.activityProvider?.currentActivity)

    // Each module class must implement the definition function. The definition consists of components
    // that describes the module's functionality and behavior.
    // See https://docs.expo.dev/modules/module-api for more details about available components.
    override fun definition() = ModuleDefinition {
        // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
        // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
        // The module will be accessible from `requireNativeModule('MyModule')` in JavaScript.
        Name("MyModule")

        // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
        Constants(
            "PI" to Math.PI
        )

        // Defines event names that the module can send to JavaScript.
        Events("onChange")

        // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
        Function("hello") {
            "Hello world! 👋"
        }

        // Defines a JavaScript function that always returns a Promise and whose native code
        // is by default dispatched on the different thread than the JavaScript runtime runs on.
        AsyncFunction("setValueAsync") { value: String ->
            // Send an event to JavaScript.
            sendEvent(
                "onChange", mapOf(
                    "value" to value
                )
            )
        }

        // Enables the module to be used as a native view. Definition components that are accepted as part of
        // the view definition: Prop, Events.
        View(MyModuleView::class) {
            // Defines a setter for the `url` prop.
            Prop("url") { view: MyModuleView, url: URL ->
                view.webView.loadUrl(url.toString())
            }
            // Defines an event that the view can send to JavaScript.
            Events("onLoad")
        }

        AsyncFunction("startRecording") {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            intent.putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            intent.putExtra(
                RecognizerIntent.EXTRA_LANGUAGE,
                Locale.getDefault()
            )
            intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak to text")

            try {
                activity.startActivityForResult(intent, REQUEST_CODE_SPEECH_INPUT)
            } catch (e: Exception) {
                // on below line we are displaying error message in toast
                Toast
                    .makeText(
                        activity, " " + e.message,
                        Toast.LENGTH_SHORT
                    )
                    .show()
            }

            // Send an event to JavaScript.

        }

        OnActivityResult { activity, onActivityResultPayload ->
            val data = onActivityResultPayload.data
            if (onActivityResultPayload.requestCode == REQUEST_CODE_SPEECH_INPUT && onActivityResultPayload.resultCode == RESULT_OK) {
                val res: ArrayList<String> =
                    data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS) as ArrayList<String>
                sendEvent(
                    "onChange", mapOf(
                        "value" to res.joinToString(", ")
                    )
                )
            }
        }
    }
}
