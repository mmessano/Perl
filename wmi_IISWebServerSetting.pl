use strict;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my @computers = ("PAWEB5");
foreach my $computer (@computers) {
   print "\n";
   print "==========================================\n";
   print "Computer: $computer\n";
   print "==========================================\n";

   my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\MicrosoftIISv2") or die "WMI connection failed.\n";
   my $colItems = $objWMIService->ExecQuery("SELECT * FROM IIsWebServerSetting", "WQL",
                  wbemFlagReturnImmediately | wbemFlagForwardOnly);

   foreach my $objItem (in $colItems) {
      print "AccessExecute: $objItem->{AccessExecute}\n";
      print "AccessFlags: $objItem->{AccessFlags}\n";
      print "AccessNoPhysicalDir: $objItem->{AccessNoPhysicalDir}\n";
      print "AccessNoRemoteExecute: $objItem->{AccessNoRemoteExecute}\n";
      print "AccessNoRemoteRead: $objItem->{AccessNoRemoteRead}\n";
      print "AccessNoRemoteScript: $objItem->{AccessNoRemoteScript}\n";
      print "AccessNoRemoteWrite: $objItem->{AccessNoRemoteWrite}\n";
      print "AccessRead: $objItem->{AccessRead}\n";
      print "AccessScript: $objItem->{AccessScript}\n";
      print "AccessSource: $objItem->{AccessSource}\n";
      print "AccessSSL: $objItem->{AccessSSL}\n";
      print "AccessSSL128: $objItem->{AccessSSL128}\n";
      print "AccessSSLFlags: $objItem->{AccessSSLFlags}\n";
      print "AccessSSLMapCert: $objItem->{AccessSSLMapCert}\n";
      print "AccessSSLNegotiateCert: $objItem->{AccessSSLNegotiateCert}\n";
      print "AccessSSLRequireCert: $objItem->{AccessSSLRequireCert}\n";
      print "AccessWrite: $objItem->{AccessWrite}\n";
      print "AdminACLBin: " . join(",", (in $objItem->{AdminACLBin})) . "\n";
      print "AllowKeepAlive: $objItem->{AllowKeepAlive}\n";
      print "AllowPathInfoForScriptMappings: $objItem->{AllowPathInfoForScriptMappings}\n";
      print "AnonymousPasswordSync: $objItem->{AnonymousPasswordSync}\n";
      print "AnonymousUserName: $objItem->{AnonymousUserName}\n";
      print "AnonymousUserPass: $objItem->{AnonymousUserPass}\n";
      print "AppAllowClientDebug: $objItem->{AppAllowClientDebug}\n";
      print "AppAllowDebugging: $objItem->{AppAllowDebugging}\n";
      print "AppFriendlyName: $objItem->{AppFriendlyName}\n";
      print "AppOopRecoverLimit: $objItem->{AppOopRecoverLimit}\n";
      print "AppPoolId: $objItem->{AppPoolId}\n";
      print "AppWamClsid: $objItem->{AppWamClsid}\n";
      print "AspAllowOutOfProcComponents: $objItem->{AspAllowOutOfProcComponents}\n";
      print "AspAllowSessionState: $objItem->{AspAllowSessionState}\n";
      print "AspAppServiceFlags: $objItem->{AspAppServiceFlags}\n";
      print "AspBufferingLimit: $objItem->{AspBufferingLimit}\n";
      print "AspBufferingOn: $objItem->{AspBufferingOn}\n";
      print "AspCalcLineNumber: $objItem->{AspCalcLineNumber}\n";
      print "AspCodepage: $objItem->{AspCodepage}\n";
      print "AspDiskTemplateCacheDirectory: $objItem->{AspDiskTemplateCacheDirectory}\n";
      print "AspEnableApplicationRestart: $objItem->{AspEnableApplicationRestart}\n";
      print "AspEnableAspHtmlFallback: $objItem->{AspEnableAspHtmlFallback}\n";
      print "AspEnableChunkedEncoding: $objItem->{AspEnableChunkedEncoding}\n";
      print "AspEnableParentPaths: $objItem->{AspEnableParentPaths}\n";
      print "AspEnableSxs: $objItem->{AspEnableSxs}\n";
      print "AspEnableTracker: $objItem->{AspEnableTracker}\n";
      print "AspEnableTypelibCache: $objItem->{AspEnableTypelibCache}\n";
      print "AspErrorsToNTLog: $objItem->{AspErrorsToNTLog}\n";
      print "AspExceptionCatchEnable: $objItem->{AspExceptionCatchEnable}\n";
      print "AspExecuteInMTA: $objItem->{AspExecuteInMTA}\n";
      print "AspKeepSessionIDSecure: $objItem->{AspKeepSessionIDSecure}\n";
      print "AspLCID: $objItem->{AspLCID}\n";
      print "AspLogErrorRequests: $objItem->{AspLogErrorRequests}\n";
      print "AspMaxDiskTemplateCacheFiles: $objItem->{AspMaxDiskTemplateCacheFiles}\n";
      print "AspMaxRequestEntityAllowed: $objItem->{AspMaxRequestEntityAllowed}\n";
      print "AspPartitionID: $objItem->{AspPartitionID}\n";
      print "AspProcessorThreadMax: $objItem->{AspProcessorThreadMax}\n";
      print "AspQueueConnectionTestTime: $objItem->{AspQueueConnectionTestTime}\n";
      print "AspQueueTimeout: $objItem->{AspQueueTimeout}\n";
      print "AspRequestQueueMax: $objItem->{AspRequestQueueMax}\n";
      print "AspRunOnEndAnonymously: $objItem->{AspRunOnEndAnonymously}\n";
      print "AspScriptEngineCacheMax: $objItem->{AspScriptEngineCacheMax}\n";
      print "AspScriptErrorMessage: $objItem->{AspScriptErrorMessage}\n";
      print "AspScriptErrorSentToBrowser: $objItem->{AspScriptErrorSentToBrowser}\n";
      print "AspScriptFileCacheSize: $objItem->{AspScriptFileCacheSize}\n";
      print "AspScriptLanguage: $objItem->{AspScriptLanguage}\n";
      print "AspScriptTimeout: $objItem->{AspScriptTimeout}\n";
      print "AspSessionMax: $objItem->{AspSessionMax}\n";
      print "AspSessionTimeout: $objItem->{AspSessionTimeout}\n";
      print "AspSxsName: $objItem->{AspSxsName}\n";
      print "AspTrackThreadingModel: $objItem->{AspTrackThreadingModel}\n";
      print "AspUsePartition: $objItem->{AspUsePartition}\n";
      print "AuthAdvNotifyDisable: $objItem->{AuthAdvNotifyDisable}\n";
      print "AuthAnonymous: $objItem->{AuthAnonymous}\n";
      print "AuthBasic: $objItem->{AuthBasic}\n";
      print "AuthChangeDisable: $objItem->{AuthChangeDisable}\n";
      print "AuthChangeUnsecure: $objItem->{AuthChangeUnsecure}\n";
      print "AuthFlags: $objItem->{AuthFlags}\n";
      print "AuthMD5: $objItem->{AuthMD5}\n";
      print "AuthNTLM: $objItem->{AuthNTLM}\n";
      print "AuthPassport: $objItem->{AuthPassport}\n";
      print "AuthPersistence: $objItem->{AuthPersistence}\n";
      print "AuthPersistSingleRequest: $objItem->{AuthPersistSingleRequest}\n";
      print "AzEnable: $objItem->{AzEnable}\n";
      print "AzImpersonationLevel: $objItem->{AzImpersonationLevel}\n";
      print "AzScopeName: $objItem->{AzScopeName}\n";
      print "AzStoreName: $objItem->{AzStoreName}\n";
      print "CacheControlCustom: $objItem->{CacheControlCustom}\n";
      print "CacheControlMaxAge: $objItem->{CacheControlMaxAge}\n";
      print "CacheControlNoCache: $objItem->{CacheControlNoCache}\n";
      print "CacheISAPI: $objItem->{CacheISAPI}\n";
      print "Caption: $objItem->{Caption}\n";
      print "CertCheckMode: $objItem->{CertCheckMode}\n";
      print "CGITimeout: $objItem->{CGITimeout}\n";
      print "ClusterEnabled: $objItem->{ClusterEnabled}\n";
      print "ConnectionTimeout: $objItem->{ConnectionTimeout}\n";
      print "ContentIndexed: $objItem->{ContentIndexed}\n";
      print "CreateCGIWithNewConsole: $objItem->{CreateCGIWithNewConsole}\n";
      print "CreateProcessAsUser: $objItem->{CreateProcessAsUser}\n";
      print "DefaultDoc: $objItem->{DefaultDoc}\n";
      print "DefaultDocFooter: $objItem->{DefaultDocFooter}\n";
      print "DefaultLogonDomain: $objItem->{DefaultLogonDomain}\n";
      print "Description: $objItem->{Description}\n";
      print "DirBrowseFlags: $objItem->{DirBrowseFlags}\n";
      print "DirBrowseShowDate: $objItem->{DirBrowseShowDate}\n";
      print "DirBrowseShowExtension: $objItem->{DirBrowseShowExtension}\n";
      print "DirBrowseShowLongDate: $objItem->{DirBrowseShowLongDate}\n";
      print "DirBrowseShowSize: $objItem->{DirBrowseShowSize}\n";
      print "DirBrowseShowTime: $objItem->{DirBrowseShowTime}\n";
      print "DisableSocketPooling: $objItem->{DisableSocketPooling}\n";
      print "DisableStaticFileCache: $objItem->{DisableStaticFileCache}\n";
      print "DoDynamicCompression: $objItem->{DoDynamicCompression}\n";
      print "DontLog: $objItem->{DontLog}\n";
      print "DoStaticCompression: $objItem->{DoStaticCompression}\n";
      print "EnableDefaultDoc: $objItem->{EnableDefaultDoc}\n";
      print "EnableDirBrowsing: $objItem->{EnableDirBrowsing}\n";
      print "EnableDocFooter: $objItem->{EnableDocFooter}\n";
      print "EnableReverseDns: $objItem->{EnableReverseDns}\n";
      print "FrontPageWeb: $objItem->{FrontPageWeb}\n";
      print "HttpCustomHeaders: " . join(",", (in $objItem->{HttpCustomHeaders})) . "\n";
      print "HttpErrors: " . join(",", (in $objItem->{HttpErrors})) . "\n";
      print "HttpExpires: $objItem->{HttpExpires}\n";
      print "HttpPics: " . join(",", (in $objItem->{HttpPics})) . "\n";
      print "LogExtFileBytesRecv: $objItem->{LogExtFileBytesRecv}\n";
      print "LogExtFileBytesSent: $objItem->{LogExtFileBytesSent}\n";
      print "LogExtFileClientIp: $objItem->{LogExtFileClientIp}\n";
      print "LogExtFileComputerName: $objItem->{LogExtFileComputerName}\n";
      print "LogExtFileCookie: $objItem->{LogExtFileCookie}\n";
      print "LogExtFileDate: $objItem->{LogExtFileDate}\n";
      print "LogExtFileFlags: $objItem->{LogExtFileFlags}\n";
      print "LogExtFileHost: $objItem->{LogExtFileHost}\n";
      print "LogExtFileHttpStatus: $objItem->{LogExtFileHttpStatus}\n";
      print "LogExtFileHttpSubStatus: $objItem->{LogExtFileHttpSubStatus}\n";
      print "LogExtFileMethod: $objItem->{LogExtFileMethod}\n";
      print "LogExtFileProtocolVersion: $objItem->{LogExtFileProtocolVersion}\n";
      print "LogExtFileReferer: $objItem->{LogExtFileReferer}\n";
      print "LogExtFileServerIp: $objItem->{LogExtFileServerIp}\n";
      print "LogExtFileServerPort: $objItem->{LogExtFileServerPort}\n";
      print "LogExtFileSiteName: $objItem->{LogExtFileSiteName}\n";
      print "LogExtFileTime: $objItem->{LogExtFileTime}\n";
      print "LogExtFileTimeTaken: $objItem->{LogExtFileTimeTaken}\n";
      print "LogExtFileUriQuery: $objItem->{LogExtFileUriQuery}\n";
      print "LogExtFileUriStem: $objItem->{LogExtFileUriStem}\n";
      print "LogExtFileUserAgent: $objItem->{LogExtFileUserAgent}\n";
      print "LogExtFileUserName: $objItem->{LogExtFileUserName}\n";
      print "LogExtFileWin32Status: $objItem->{LogExtFileWin32Status}\n";
      print "LogFileDirectory: $objItem->{LogFileDirectory}\n";
      print "LogFileLocaltimeRollover: $objItem->{LogFileLocaltimeRollover}\n";
      print "LogFilePeriod: $objItem->{LogFilePeriod}\n";
      print "LogFileTruncateSize: $objItem->{LogFileTruncateSize}\n";
      print "LogOdbcDataSource: $objItem->{LogOdbcDataSource}\n";
      print "LogOdbcPassword: $objItem->{LogOdbcPassword}\n";
      print "LogOdbcTableName: $objItem->{LogOdbcTableName}\n";
      print "LogOdbcUserName: $objItem->{LogOdbcUserName}\n";
      print "LogonMethod: $objItem->{LogonMethod}\n";
      print "LogPluginClsid: $objItem->{LogPluginClsid}\n";
      print "LogType: $objItem->{LogType}\n";
      print "MaxBandwidth: $objItem->{MaxBandwidth}\n";
      print "MaxBandwidthBlocked: $objItem->{MaxBandwidthBlocked}\n";
      print "MaxConnections: $objItem->{MaxConnections}\n";
      print "MaxEndpointConnections: $objItem->{MaxEndpointConnections}\n";
      print "MaxRequestEntityAllowed: $objItem->{MaxRequestEntityAllowed}\n";
      print "MimeMap: " . join(",", (in $objItem->{MimeMap})) . "\n";
      print "Name: $objItem->{Name}\n";
      print "NTAuthenticationProviders: $objItem->{NTAuthenticationProviders}\n";
      print "PassportRequireADMapping: $objItem->{PassportRequireADMapping}\n";
      print "PasswordCacheTTL: $objItem->{PasswordCacheTTL}\n";
      print "PasswordChangeFlags: $objItem->{PasswordChangeFlags}\n";
      print "PasswordExpirePrenotifyDays: $objItem->{PasswordExpirePrenotifyDays}\n";
      print "PoolIdcTimeout: $objItem->{PoolIdcTimeout}\n";
      print "ProcessNTCRIfLoggedOn: $objItem->{ProcessNTCRIfLoggedOn}\n";
      print "Realm: $objItem->{Realm}\n";
      print "RedirectHeaders: " . join(",", (in $objItem->{RedirectHeaders})) . "\n";
      print "RevocationFreshnessTime: $objItem->{RevocationFreshnessTime}\n";
      print "RevocationURLRetrievalTimeout: $objItem->{RevocationURLRetrievalTimeout}\n";
      print "ScriptMaps: " . join(",", (in $objItem->{ScriptMaps})) . "\n";
      print "SecureBindings: " . join(",", (in $objItem->{SecureBindings})) . "\n";
      print "ServerAutoStart: $objItem->{ServerAutoStart}\n";
      print "ServerBindings: " . join(",", (in $objItem->{ServerBindings})) . "\n";
      print "ServerCommand: $objItem->{ServerCommand}\n";
      print "ServerComment: $objItem->{ServerComment}\n";
      print "ServerID: $objItem->{ServerID}\n";
      print "ServerListenBacklog: $objItem->{ServerListenBacklog}\n";
      print "ServerListenTimeout: $objItem->{ServerListenTimeout}\n";
      print "ServerSize: $objItem->{ServerSize}\n";
      print "SetHostName: $objItem->{SetHostName}\n";
      print "SettingID: $objItem->{SettingID}\n";
      print "ShutdownTimeLimit: $objItem->{ShutdownTimeLimit}\n";
      print "SSIExecDisable: $objItem->{SSIExecDisable}\n";
      print "SSLAlwaysNegoClientCert: $objItem->{SSLAlwaysNegoClientCert}\n";
      print "SslCtlIdentifier: $objItem->{SslCtlIdentifier}\n";
      print "SslCtlStoreName: $objItem->{SslCtlStoreName}\n";
      print "SSLStoreName: $objItem->{SSLStoreName}\n";
      print "TraceUriPrefix: " . join(",", (in $objItem->{TraceUriPrefix})) . "\n";
      print "UploadReadAheadSize: $objItem->{UploadReadAheadSize}\n";
      print "UseDigestSSP: $objItem->{UseDigestSSP}\n";
      print "UseHostName: $objItem->{UseHostName}\n";
      print "WebDAVMaxAttributesPerElement: $objItem->{WebDAVMaxAttributesPerElement}\n";
      print "Win32Error: $objItem->{Win32Error}\n";
      print "\n";
   }
}