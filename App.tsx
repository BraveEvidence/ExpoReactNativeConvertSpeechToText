import { StatusBar } from "expo-status-bar";
import {
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import MyModule from "./modules/my-module";
import { useEffect, useState } from "react";

export default function App() {
  const [text, setText] = useState("");

  useEffect(() => {
    const subscription = MyModule.addListener("onChange", (data) => {
      if (
        data.value !== undefined &&
        data.value !== null &&
        data.value !== ""
      ) {
        setText(text + " " + data.value);
      }
    });
    return () => subscription.remove();
  }, []);

  return (
    <View style={styles.container}>
      <Text>Open up App.tsx to start working on your app!</Text>
      <StatusBar style="auto" />
      <TouchableOpacity
        onPress={async () => {
          await MyModule.startRecording();
        }}>
        <Text style={{ color: "blue", fontSize: 30 }}>Start Recording</Text>
      </TouchableOpacity>
      {Platform.OS === "ios" && (
        <TouchableOpacity
          onPress={async () => {
            await MyModule.stopRecording();
          }}>
          <Text style={{ color: "red", fontSize: 30 }}>Stop Recording</Text>
        </TouchableOpacity>
      )}
      <Text style={{ color: "red", fontSize: 20 }}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fff",
    alignItems: "center",
    justifyContent: "center",
  },
});

//https://www.youtube.com/playlist?list=PLQhQEGkwKZUpqfjPZfYHfIiTYzTy2srMH
//https://www.youtube.com/playlist?list=PLQhQEGkwKZUry7n4CPSlxviUJSTlkUYjf
