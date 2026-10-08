import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { RootStackParamList } from '../types/navigation';
import { useAppStore } from '../store/useAppStore';
import { KidColors } from '../theme/colors';

// Screens
import { DevicePairingScreen } from '../screens/DevicePairingScreen';
import { KidHomeScreen } from '../screens/KidHomeScreen';
import { KidPlayerScreen } from '../screens/KidPlayerScreen';
import { KidShortsFeedScreen } from '../screens/KidShortsFeedScreen';
import { ParentSecurityScreen } from '../screens/ParentSecurityScreen';
import { ParentDashboardScreen } from '../screens/ParentDashboardScreen';
import { ParentMediaLibraryScreen } from '../screens/ParentMediaLibraryScreen';
import { ParentStorageScreen } from '../screens/ParentStorageScreen';
import { ParentServerScreen } from '../screens/ParentServerScreen';
import { ParentAnalyticsScreen } from '../screens/ParentAnalyticsScreen';

const Stack = createNativeStackNavigator<RootStackParamList>();

const theme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: KidColors.bgDark,
    card: KidColors.cardDark,
    text: KidColors.textLight,
    border: KidColors.borderDark,
    primary: KidColors.primary,
  },
};

export const RootNavigator: React.FC = () => {
  const { isInitialized, isDevicePaired } = useAppStore();

  if (!isInitialized) {
    return (
      <View style={styles.splashContainer}>
        <Text style={styles.splashIcon}>📺</Text>
        <Text style={styles.splashTitle}>KidsTube</Text>
        <ActivityIndicator
          size="large"
          color={KidColors.primary}
          style={{ marginTop: 24 }}
        />
      </View>
    );
  }

  return (
    <NavigationContainer theme={theme}>
      <Stack.Navigator
        initialRouteName={isDevicePaired ? 'KidHome' : 'DevicePairing'}
        screenOptions={{
          headerShown: false,
          animation: 'fade',
          contentStyle: { backgroundColor: KidColors.bgDark },
        }}
      >
        <Stack.Screen name="DevicePairing" component={DevicePairingScreen} />
        <Stack.Screen name="KidHome" component={KidHomeScreen} />
        <Stack.Screen name="KidPlayer" component={KidPlayerScreen} />
        <Stack.Screen
          name="KidShortsFeed"
          component={KidShortsFeedScreen}
          options={{ animation: 'slide_from_bottom' }}
        />
        <Stack.Screen name="ParentSecurity" component={ParentSecurityScreen} />
        <Stack.Screen name="ParentDashboard" component={ParentDashboardScreen} />
        <Stack.Screen
          name="ParentMediaLibrary"
          component={ParentMediaLibraryScreen}
        />
        <Stack.Screen name="ParentStorage" component={ParentStorageScreen} />
        <Stack.Screen name="ParentServer" component={ParentServerScreen} />
        <Stack.Screen
          name="ParentAnalytics"
          component={ParentAnalyticsScreen}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
};

const styles = StyleSheet.create({
  splashContainer: {
    flex: 1,
    backgroundColor: KidColors.bgDark,
    justifyContent: 'center',
    alignItems: 'center',
  },
  splashIcon: {
    fontSize: 64,
    marginBottom: 12,
  },
  splashTitle: {
    color: KidColors.textLight,
    fontSize: 28,
    fontWeight: '900',
    letterSpacing: -0.5,
  },
});
