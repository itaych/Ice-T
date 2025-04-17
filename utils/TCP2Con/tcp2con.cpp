// tcp2con by Itay Chamiel

#define _CRT_SECURE_NO_WARNINGS
#define WIN32_LEAN_AND_MEAN
#ifdef UNICODE
#error please change "character set" setting to "Not set".
#endif

#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdio.h>
#include <windows.h>
#include <string>

// Need to link with Ws2_32.lib
#pragma comment(lib, "ws2_32.lib")

#define APPNAME "tcp2con 1.0"
#define FULLAPPNAME APPNAME " by Itay Chamiel, Dec. 4 2013"
#define DEFAULT_LISTEN_PORT 9001
#define BUFSIZE 4096

HANDLE g_hChildStd_IN_Rd = NULL, g_hChildStd_IN_Wr = NULL;
HANDLE g_hChildStd_OUT_Rd = NULL, g_hChildStd_OUT_Wr = NULL;

void CreateChildProcess(std::string);
void WriteToPipe(void);
void ReadFromPipe(void);
void ErrorExit(const char*);

SOCKET g_AcceptSocket;
PROCESS_INFORMATION g_piProcInfo;

DWORD WINAPI proc2net(LPVOID lpThreadParameter);
DWORD WINAPI net2proc(LPVOID lpThreadParameter);

int main(int argc, char *argv[])
{
	bool arg_endless_loop = true, arg_public = false;
	int arg_port = DEFAULT_LISTEN_PORT;

	int i;

	if (argc == 1)
	{
		printf("Usage: %s [options] commandline [command line arguments]\n\n"
			"Available options:\n\n"
			"-v      : print version information and exit.\n"
			"-p=port : set listening port number (default %d).\n"
			"-o      : once - exit after one session.\n"
			"-a      : public access. Allows access from addresses other than localhost.\n"
			"\n"
			, argv[0], DEFAULT_LISTEN_PORT);
		ExitProcess(1);
	}

	// parse command line arguments
	for (i=1; i<argc; i++)
	{
		if (argv[i][0] != '-')
			break;
		switch(argv[i][1])
		{
		case 'v':
			printf("%s\n", FULLAPPNAME);
			ExitProcess(0);
			break;
		case 'o':
			arg_endless_loop = false;
			break;
		case 'a':
			arg_public = true;
			break;
		case 'p':
			if (strlen(argv[i]) >= 4 && argv[i][2] == '=')
			{
				int port = atoi(&argv[i][3]);
				if (port > 0)
				arg_port = port;
			}
			break;
		default:
			printf("Warning: unknown argument %s\n", argv[i]);
		}
	}

	if (i == argc)
	{
		printf("Error: no command given\n");
		ExitProcess(1);
	}

	// Try to access executable file
	{
		FILE* fp = fopen(argv[i], "r");
		if (!fp)
		{
			printf("Error: file %s not found\n", argv[i]);
			ExitProcess(1);
		}
		fclose(fp);
	}

	std::string cmdline = "";

	for (; i<argc; i++)
	{
		cmdline += argv[i];
		if (i != argc-1)
			cmdline += " ";
	}

	//----------------------
	// Initialize Winsock.
	WSADATA wsaData;
	int iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
	if (iResult != NO_ERROR) {
		printf("WSAStartup failed with error: %ld\n", iResult);
		return 1;
	}
	//----------------------
	// Create a SOCKET for listening for
	// incoming connection requests.
	SOCKET ListenSocket;
	ListenSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (ListenSocket == INVALID_SOCKET) {
		printf("socket failed with error: %ld\n", WSAGetLastError());
		WSACleanup();
		return 1;
	}
	//----------------------
	// The sockaddr_in structure specifies the address family,
	// IP address, and port for the socket that is being bound.
	sockaddr_in service;
	service.sin_family = AF_INET;
	service.sin_addr.s_addr = (arg_public? INADDR_ANY : inet_addr("127.0.0.1"));
	service.sin_port = htons(arg_port);

	if (bind(ListenSocket,
		(SOCKADDR *) & service, sizeof (service)) == SOCKET_ERROR) {
		printf("bind failed with error: %ld\n", WSAGetLastError());
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}
	//----------------------
	// Listen for incoming connection requests.
	// on the created socket
	if (listen(ListenSocket, 1) == SOCKET_ERROR) {
		printf("listen failed with error: %ld\n", WSAGetLastError());
		closesocket(ListenSocket);
		WSACleanup();
		return 1;
	}

	do
	{
		//----------------------
		// Create a SOCKET for accepting incoming requests.
		printf("Listening on port %d...\n", arg_port);

		//----------------------
		// Accept the connection.
		struct sockaddr_in client_address;
		int client_len = sizeof(client_address);
		g_AcceptSocket = accept(ListenSocket, (struct sockaddr *)&client_address, &client_len);
		if (g_AcceptSocket == INVALID_SOCKET) {
			printf("accept failed with error: %ld\n", WSAGetLastError());
			continue;
		}

		char clntName[INET_ADDRSTRLEN];
		inet_ntop(AF_INET, &client_address.sin_addr.s_addr, clntName, sizeof(clntName));

		printf("Client connected: %s:%d\n", clntName, ntohs(client_address.sin_port));

		// Check source of connection
		if (!arg_public && client_address.sin_addr.s_addr != inet_addr("127.0.0.1"))
		{
			// This should never actually happen as in non-public mode we only bind to local interface
			printf("Denying connection from non-local client.\n\n");
			closesocket(g_AcceptSocket);
			continue;
		}

		// Give our client a warm welcome
		std::string welcomeString = "Welcome to ";
		welcomeString += APPNAME;
		welcomeString += " running ";
		welcomeString += cmdline;
		welcomeString += "\r\n";
		int ret = send(g_AcceptSocket, welcomeString.c_str(), strlen(welcomeString.c_str()), 0);
		if (ret != strlen(welcomeString.c_str()))
		{
			closesocket(g_AcceptSocket);
			continue;
		}

		// Initialize process handles.
		SECURITY_ATTRIBUTES saAttr;

		// Set the bInheritHandle flag so pipe handles are inherited.
		saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
		saAttr.bInheritHandle = TRUE;
		saAttr.lpSecurityDescriptor = NULL;

		// Create a pipe for the child process's STDOUT.
		if (!CreatePipe(&g_hChildStd_OUT_Rd, &g_hChildStd_OUT_Wr, &saAttr, 0))
			ErrorExit("StdoutRd CreatePipe");
		// Ensure the read handle to the pipe for STDOUT is not inherited.
		if (!SetHandleInformation(g_hChildStd_OUT_Rd, HANDLE_FLAG_INHERIT, 0))
			ErrorExit("Stdout SetHandleInformation");

		// Create a pipe for the child process's STDIN.
		if (!CreatePipe(&g_hChildStd_IN_Rd, &g_hChildStd_IN_Wr, &saAttr, 0))
			ErrorExit("Stdin CreatePipe");
		// Ensure the write handle to the pipe for STDIN is not inherited.
		if (!SetHandleInformation(g_hChildStd_IN_Wr, HANDLE_FLAG_INHERIT, 0))
			ErrorExit("Stdin SetHandleInformation");

		// Create the child process.
		printf("Executing command: %s\n", cmdline.c_str());
		CreateChildProcess(cmdline);

		// Create proc2net and net2proc threads
		HANDLE hThreadArray[2];
		hThreadArray[0] = CreateThread(NULL, 10000, proc2net, (LPVOID)NULL, 0, NULL);
		hThreadArray[1] = CreateThread(NULL, 10000, net2proc, (LPVOID)NULL, 0, NULL);
		printf("Session in progress.\n");

		// Wait for either one of the threads to die
		int done_thread = WaitForMultipleObjects(2, hThreadArray, FALSE, INFINITE);

		printf("Session closing due to %s.\n",
			(done_thread == 0? "process exit" : "client socket shutdown")
			);

		CloseHandle(hThreadArray[done_thread]);

		// Close the socket and nuke the process if it still exists
		if (done_thread == 0)
			Sleep(1000); // if process exited, let TCP send flush before closing socket
		closesocket(g_AcceptSocket);
		TerminateProcess(g_piProcInfo.hProcess, 0);
		CloseHandle(g_piProcInfo.hProcess);

		// That should cause the other thread to die too - wait for it
		done_thread = !done_thread;
		WaitForSingleObject(hThreadArray[done_thread], INFINITE);
		CloseHandle(hThreadArray[done_thread]);

		CloseHandle(g_hChildStd_OUT_Rd);
		CloseHandle(g_hChildStd_IN_Wr);

		printf("Done.\n\n");
	} while(arg_endless_loop);

	closesocket(ListenSocket);

	WSACleanup();
	return 0;
}

// Create a child process that uses the previously created pipes for STDIN and STDOUT.
void CreateChildProcess(std::string cmd)
{
	const char* user_cmdline = cmd.c_str();
	char* szCmdline = (char*)malloc(strlen(user_cmdline)+1);
	strcpy(szCmdline, user_cmdline);

	STARTUPINFO siStartInfo;
	BOOL bSuccess = FALSE;

	// Set up members of the PROCESS_INFORMATION structure.

	ZeroMemory(&g_piProcInfo, sizeof(PROCESS_INFORMATION));

	// Set up members of the STARTUPINFO structure.
	// This structure specifies the STDIN and STDOUT handles for redirection.

	ZeroMemory(&siStartInfo, sizeof(STARTUPINFO));
	siStartInfo.cb = sizeof(STARTUPINFO);
	siStartInfo.hStdError = g_hChildStd_OUT_Wr;
	siStartInfo.hStdOutput = g_hChildStd_OUT_Wr;
	siStartInfo.hStdInput = g_hChildStd_IN_Rd;
	siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

	// Create the child process.

	bSuccess = CreateProcess(NULL,
		szCmdline,     // command line
		NULL,          // process security attributes
		NULL,          // primary thread security attributes
		TRUE,          // handles are inherited
		0,             // creation flags
		NULL,          // use parent's environment
		NULL,          // use parent's current directory
		&siStartInfo,  // STARTUPINFO pointer
		&g_piProcInfo);  // receives PROCESS_INFORMATION

	// If an error occurs, exit the application.
	if (!bSuccess)
		ErrorExit("CreateProcess");

	// We don't need access to the child process's primary thread, so close handle.
	CloseHandle(g_piProcInfo.hThread);
	// Close handles to streams we have given to child process.
	CloseHandle(g_hChildStd_OUT_Wr);
	CloseHandle(g_hChildStd_IN_Rd);
	printf("Created pid %d\n", g_piProcInfo.dwProcessId);

	free(szCmdline);
}

// This thread reads data from the process standard output and sends to the TCP socket.
DWORD WINAPI proc2net(LPVOID lpThreadParameter)
{
	DWORD dwRead;
	CHAR chBuf[BUFSIZE];
	BOOL bSuccess = FALSE;

	for (;;)
	{
		bSuccess = ReadFile(g_hChildStd_OUT_Rd, chBuf, BUFSIZE, &dwRead, NULL);
		if(!bSuccess || dwRead == 0 ) break;

		int ret = send(g_AcceptSocket, chBuf, dwRead, 0);
		if (ret != dwRead) break;
	}
	return 0;
}

// This thread reads from the TCP socket and sends to the process standard input.
DWORD WINAPI net2proc(LPVOID lpThreadParameter)
{
	DWORD dwWritten;
	CHAR chBuf[BUFSIZE];
	BOOL bSuccess = FALSE;

	for (;;)
	{
		int num = recv(g_AcceptSocket, chBuf, BUFSIZE, 0);
		if (num < 1) break;

		bSuccess = WriteFile(g_hChildStd_IN_Wr, chBuf, num, &dwWritten, NULL);
		if (!bSuccess) break;
	}
	return 0;
}

// Format a readable error message, and exit from the application.
void ErrorExit(const char* lpszFunction)
{
	LPVOID lpMsgBuf;
	DWORD dw = GetLastError();

	FormatMessage(
		FORMAT_MESSAGE_ALLOCATE_BUFFER |
		FORMAT_MESSAGE_FROM_SYSTEM |
		FORMAT_MESSAGE_IGNORE_INSERTS,
		NULL,
		dw,
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		(LPTSTR) &lpMsgBuf,
		0, NULL );

	printf("%s failed with error %d: %s\n",
	lpszFunction, dw, lpMsgBuf);

	LocalFree(lpMsgBuf);
	ExitProcess(1);
}
