import React, { useEffect } from 'react';
import { StatusBar } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { RootNavigator } from './src/navigation/RootNavigator';
import { useAppStore } from './src/store/useAppStore';
import { KidColors } from './src/theme/colors';

export default function App() {
  const initApp = useAppStore((state) => state.initApp);

  useEffect(() => {
    initApp();
  }, [initApp]);

  return (
    <SafeAreaProvider style={{ backgroundColor: KidColors.bgDark }}>
      <StatusBar barStyle="light-content" backgroundColor={KidColors.bgDark} />
      <RootNavigator />
    </SafeAreaProvider>
  );
}
