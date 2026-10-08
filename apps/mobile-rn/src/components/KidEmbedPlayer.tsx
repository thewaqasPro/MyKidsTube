import React, { useState } from 'react';
import { View, StyleSheet, ActivityIndicator } from 'react-native';
import { WebView } from 'react-native-webview';
import { KidColors } from '../theme/colors';
import { getYoutubeEmbedUrl } from '../utils/urlHelpers';

interface Props {
  youtubeId: string;
  autoplay?: boolean;
  onEnded?: () => void;
  style?: any;
}

export const KidEmbedPlayer: React.FC<Props> = ({
  youtubeId,
  autoplay = true,
  onEnded,
  style,
}) => {
  const [isLoading, setIsLoading] = useState(true);
  const embedUrl = getYoutubeEmbedUrl(youtubeId, autoplay);

  const customHTML = `
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body, html { width: 100%; height: 100%; background: #000; overflow: hidden; display: flex; align-items: center; justify-content: center; }
          iframe { width: 100%; height: 100%; border: none; }
        </style>
      </head>
      <body>
        <iframe
          src="${embedUrl}&enablejsapi=1"
          frameborder="0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowfullscreen>
        </iframe>
        <script>
          // Listen for player end messages if needed
          window.addEventListener('message', function(e) {
            try {
              var data = JSON.parse(e.data);
              if (data.event === 'onStateChange' && data.info === 0) {
                window.ReactNativeWebView.postMessage(JSON.stringify({ event: 'ended' }));
              }
            } catch (_) {}
          });
        </script>
      </body>
    </html>
  `;

  return (
    <View style={[styles.container, style]}>
      <WebView
        source={{ html: customHTML, baseUrl: 'https://www.youtube-nocookie.com' }}
        style={styles.webview}
        javaScriptEnabled={true}
        domStorageEnabled={true}
        allowsInlineMediaPlayback={true}
        mediaPlaybackRequiresUserAction={false}
        allowsFullscreenVideo={true}
        onLoadEnd={() => setIsLoading(false)}
        onMessage={(event) => {
          try {
            const data = JSON.parse(event.nativeEvent.data);
            if (data.event === 'ended' && onEnded) {
              onEnded();
            }
          } catch (_) {}
        }}
        originWhitelist={['https://*.youtube-nocookie.com', 'https://*.youtube.com', 'about:blank']}
      />

      {isLoading && (
        <View style={styles.loaderContainer}>
          <ActivityIndicator size="large" color={KidColors.primary} />
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    aspectRatio: 16 / 9,
    backgroundColor: '#000',
    position: 'relative',
  },
  webview: {
    flex: 1,
    backgroundColor: '#000',
  },
  loaderContainer: {
    ...StyleSheet.absoluteFill,
    backgroundColor: '#000',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
