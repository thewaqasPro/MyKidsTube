export type RootStackParamList = {
  DevicePairing: undefined;
  ParentSecurity: {
    isForceChange?: boolean;
    destinationOnSuccess?: 'KidHome' | 'ParentDashboard';
  } | undefined;
  KidHome: undefined;
  KidPlayer: {
    videoId: string;
  };
  KidShortsFeed: {
    initialVideoId?: string;
  } | undefined;
  ParentDashboard: undefined;
  ParentMediaLibrary: undefined;
  ParentStorage: undefined;
  ParentServer: undefined;
  ParentAnalytics: undefined;
};
