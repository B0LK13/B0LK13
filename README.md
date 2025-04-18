<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Researcher | GitHub Profile</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script src="https://kit.fontawesome.com/a076d05399.js" crossorigin="anonymous"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@300;400;500;600;700&family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap');
        
        body {
            font-family: 'Inter', sans-serif;
            background-color: #0d1117;
            color: #c9d1d9;
        }
        
        .code-font {
            font-family: 'Fira Code', monospace;
        }
        
        .gradient-text {
            background: linear-gradient(90deg, #58a6ff, #8a63ff);
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
        }
        
        .card-glass {
            background: rgba(13, 17, 23, 0.7);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .skill-badge {
            background: rgba(56, 139, 253, 0.15);
            border: 1px solid rgba(56, 139, 253, 0.4);
        }
        
        .terminal-line::before {
            content: "> ";
            color: #58a6ff;
            font-weight: bold;
        }
        
        .glow-on-hover:hover {
            box-shadow: 0 0 15px rgba(88, 166, 255, 0.5);
        }
    </style>
</head>
<body class="min-h-screen">
    <div class="container mx-auto px-4 py-12 max-w-6xl">
        <!-- Header Section -->
        <header class="flex flex-col md:flex-row justify-between items-start md:items-center gap-8 mb-16">
            <div class="flex items-center gap-6">
                <img src="https://avatars.githubusercontent.com/u/583231?v=4" alt="Profile" class="w-24 h-24 rounded-full border-2 border-[#58a6ff]">
                <div>
                    <h1 class="text-3xl md:text-4xl font-bold text-white">Security Researcher</h1>
                    <p class="text-lg text-gray-400">@security-expert</p>
                </div>
            </div>
            <div class="flex gap-4">
                <a href="#" class="px-6 py-2 bg-[#238636] hover:bg-[#2ea043] text-white rounded-md font-medium flex items-center gap-2 transition-all glow-on-hover">
                    <i class="fab fa-github"></i> Follow
                </a>
                <a href="#" class="px-6 py-2 bg-[#1f6feb] hover:bg-[#2c7bff] text-white rounded-md font-medium flex items-center gap-2 transition-all glow-on-hover">
                    <i class="fas fa-envelope"></i> Contact
                </a>
            </div>
        </header>

        <!-- Main Content -->
        <main class="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <!-- Left Column -->
            <div class="lg:col-span-2 space-y-8">
                <!-- About Section -->
                <section class="card-glass rounded-xl p-6">
                    <h2 class="text-2xl font-bold text-white mb-4 flex items-center gap-2">
                        <i class="fas fa-user-secret text-[#58a6ff]"></i>
                        <span>About Me</span>
                    </h2>
                    <p class="text-gray-300 mb-4">
                        Security researcher with 8+ years of experience in vulnerability assessment, penetration testing, and reverse engineering. 
                        Passionate about finding and responsibly disclosing security vulnerabilities in open-source projects.
                    </p>
                    <div class="flex flex-wrap gap-2 mt-6">
                        <span class="skill-badge px-3 py-1 rounded-full text-sm text-[#58a6ff]">Penetration Testing</span>
                        <span class="skill-badge px-3 py-1 rounded-full text-sm text-[#58a6ff]">Reverse Engineering</span>
                        <span class="skill-badge px-3 py-1 rounded-full text-sm text-[#58a6ff]">Malware Analysis</span>
                        <span class="skill-badge px-3 py-1 rounded-full text-sm text-[#58a6ff]">Cryptography</span>
                        <span class="skill-badge px-3 py-1 rounded-full text-sm text-[#58a6ff]">Web Security</span>
                        <span class="skill-badge px-3 py-1 rounded-full text-sm text-[#58a6ff]">Network Security</span>
                    </div>
                </section>

                <!-- Featured Projects -->
                <section class="card-glass rounded-xl p-6">
                    <h2 class="text-2xl font-bold text-white mb-6 flex items-center gap-2">
                        <i class="fas fa-laptop-code text-[#58a6ff]"></i>
                        <span>Featured Projects</span>
                    </h2>
                    
                    <div class="space-y-6">
                        <!-- Project 1 -->
                        <div class="bg-[#161b22] hover:bg-[#1f2937] p-5 rounded-lg border-l-4 border-[#58a6ff] transition-all glow-on-hover">
                            <div class="flex justify-between items-start">
                                <div>
                                    <h3 class="text-xl font-semibold text-white">VulnScanner</h3>
                                    <p class="text-gray-400 text-sm mt-1">Automated vulnerability scanner for web applications</p>
                                </div>
                                <span class="text-xs px-2 py-1 bg-[#238636] text-white rounded-full">Active</span>
                            </div>
                            <div class="mt-4 flex items-center gap-4 text-sm">
                                <span class="text-gray-400"><i class="fas fa-star text-yellow-400"></i> 428</span>
                                <span class="text-gray-400"><i class="fas fa-code-branch text-blue-400"></i> 32</span>
                                <span class="text-gray-400"><i class="fas fa-circle text-red-400"></i> Python</span>
                            </div>
                        </div>
                        
                        <!-- Project 2 -->
                        <div class="bg-[#161b22] hover:bg-[#1f2937] p-5 rounded-lg border-l-4 border-[#8a63ff] transition-all glow-on-hover">
                            <div class="flex justify-between items-start">
                                <div>
                                    <h3 class="text-xl font-semibold text-white">SecurePass</h3>
                                    <p class="text-gray-400 text-sm mt-1">Cryptographically secure password manager</p>
                                </div>
                                <span class="text-xs px-2 py-1 bg-[#8957e5] text-white rounded-full">Featured</span>
                            </div>
                            <div class="mt-4 flex items-center gap-4 text-sm">
                                <span class="text-gray-400"><i class="fas fa-star text-yellow-400"></i> 1.2k</span>
                                <span class="text-gray-400"><i class="fas fa-code-branch text-blue-400"></i> 187</span>
                                <span class="text-gray-400"><i class="fas fa-circle text-yellow-400"></i> Rust</span>
                            </div>
                        </div>
                        
                        <!-- Project 3 -->
                        <div class="bg-[#161b22] hover:bg-[#1f2937] p-5 rounded-lg border-l-4 border-[#db61a2] transition-all glow-on-hover">
                            <div class="flex justify-between items-start">
                                <div>
                                    <h3 class="text-xl font-semibold text-white">MalwareDB</h3>
                                    <p class="text-gray-400 text-sm mt-1">Open-source malware analysis database</p>
                                </div>
                                <span class="text-xs px-2 py-1 bg-[#db61a2] text-white rounded-full">Community</span>
                            </div>
                            <div class="mt-4 flex items-center gap-4 text-sm">
                                <span class="text-gray-400"><i class="fas fa-star text-yellow-400"></i> 2.5k</span>
                                <span class="text-gray-400"><i class="fas fa-code-branch text-blue-400"></i> 342</span>
                                <span class="text-gray-400"><i class="fas fa-circle text-blue-400"></i> TypeScript</span>
                            </div>
                        </div>
                    </div>
                    
                    <a href="#" class="mt-6 inline-block text-[#58a6ff] hover:underline flex items-center gap-2">
                        <i class="fas fa-arrow-right"></i> View all projects
                    </a>
                </section>

                <!-- Recent Activity -->
                <section class="card-glass rounded-xl p-6">
                    <h2 class="text-2xl font-bold text-white mb-6 flex items-center gap-2">
                        <i class="fas fa-rss text-[#58a6ff]"></i>
                        <span>Recent Activity</span>
                    </h2>
                    
                    <div class="space-y-6">
                        <!-- Activity 1 -->
                        <div class="flex gap-4">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 rounded-full bg-[#58a6ff] flex items-center justify-center">
                                    <i class="fas fa-code text-white"></i>
                                </div>
                                <div class="w-0.5 h-full bg-gray-600 mt-2"></div>
                            </div>
                            <div>
                                <p class="text-gray-300">
                                    <span class="font-semibold text-white">Pushed to</span> SecurePass <span class="text-gray-400">main branch</span>
                                </p>
                                <p class="text-sm text-gray-400 mt-1">Implemented AES-256 encryption module</p>
                                <p class="text-xs text-gray-500 mt-2">2 hours ago</p>
                            </div>
                        </div>
                        
                        <!-- Activity 2 -->
                        <div class="flex gap-4">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 rounded-full bg-[#db61a2] flex items-center justify-center">
                                    <i class="fas fa-bug text-white"></i>
                                </div>
                                <div class="w-0.5 h-full bg-gray-600 mt-2"></div>
                            </div>
                            <div>
                                <p class="text-gray-300">
                                    <span class="font-semibold text-white">Disclosed vulnerability</span> in OpenSSL <span class="text-gray-400">CVE-2023-12345</span>
                                </p>
                                <p class="text-sm text-gray-400 mt-1">Reported buffer overflow in TLS handshake</p>
                                <p class="text-xs text-gray-500 mt-2">1 day ago</p>
                            </div>
                        </div>
                        
                        <!-- Activity 3 -->
                        <div class="flex gap-4">
                            <div class="flex flex-col items-center">
                                <div class="w-10 h-10 rounded-full bg-[#238636] flex items-center justify-center">
                                    <i class="fas fa-star text-white"></i>
                                </div>
                                <div class="w-0.5 h-full bg-gray-600 mt-2"></div>
                            </div>
                            <div>
                                <p class="text-gray-300">
                                    <span class="font-semibold text-white">Starred</span> ossf/scorecard <span class="text-gray-400">repository</span>
                                </p>
                                <p class="text-sm text-gray-400 mt-1">Security scorecards for open source projects</p>
                                <p class="text-xs text-gray-500 mt-2">3 days ago</p>
                            </div>
                        </div>
                    </div>
                </section>
            </div>
            
            <!-- Right Column -->
            <div class="space-y-8">
                <!-- Stats Section -->
                <section class="card-glass rounded-xl p-6">
                    <h2 class="text-2xl font-bold text-white mb-6 flex items-center gap-2">
                        <i class="fas fa-chart-bar text-[#58a6ff]"></i>
                        <span>Stats</span>
                    </h2>
                    
                    <div class="grid grid-cols-2 gap-4">
                        <div class="bg-[#161b22] p-4 rounded-lg text-center">
                            <p class="text-3xl font-bold text-white">24</p>
                            <p class="text-gray-400 text-sm">Repositories</p>
                        </div>
                        <div class="bg-[#161b22] p-4 rounded-lg text-center">
                            <p class="text-3xl font-bold text-white">5.2k</p>
                            <p class="text-gray-400 text-sm">Followers</p>
                        </div>
                        <div class="bg-[#161b22] p-4 rounded-lg text-center">
                            <p class="text-3xl font-bold text-white">42</p>
                            <p class="text-gray-400 text-sm">CVEs Found</p>
                        </div>
                        <div class="bg-[#161b22] p-4 rounded-lg text-center">
                            <p class="text-3xl font-bold text-white">8</p>
                            <p class="text-gray-400 text-sm">Years Exp</p>
                        </div>
                    </div>
                </section>
                
                <!-- Terminal Section -->
                <section class="card-glass rounded-xl p-6">
                    <div class="flex items-center gap-2 mb-4">
                        <div class="w-3 h-3 rounded-full bg-red-500"></div>
                        <div class="w-3 h-3 rounded-full bg-yellow-500"></div>
                        <div class="w-3 h-3 rounded-full bg-green-500"></div>
                        <span class="text-gray-400 text-sm ml-2">~/security-terminal</span>
                    </div>
                    
                    <div class="bg-black bg-opacity-70 rounded-lg p-4 font-mono text-sm h-64 overflow-y-auto">
                        <p class="terminal-line text-green-400">Welcome to Security Terminal v3.2</p>
                        <p class="terminal-line text-white">Last login: Today 14:32 from 192.168.1.100</p>
                        <p class="terminal-line text-white">scan --target example.com --full</p>
                        <p class="text-gray-400 ml-4">Initiating full security scan...</p>
                        <p class="text-gray-400 ml-4">[+] Port 80: HTTP - Apache 2.4.49</p>
                        <p class="text-yellow-400 ml-4">[!] Vulnerability detected: CVE-2021-41773</p>
                        <p class="text-gray-400 ml-4">[+] Port 443: HTTPS - OpenSSL 1.1.1k</p>
                        <p class="text-gray-400 ml-4">[+] Port 22: SSH - OpenSSH 8.2p1</p>
                        <p class="text-red-400 ml-4">[!] Critical: 3 vulnerabilities found</p>
                        <p class="terminal-line text-white">report --generate --format pdf</p>
                        <p class="text-gray-400 ml-4">Generating PDF report...</p>
                        <p class="text-green-400 ml-4">[+] Report saved to /reports/example.com_20230615.pdf</p>
                        <p class="terminal-line text-white blink">_</p>
                    </div>
                </section>
                
                <!-- Certifications -->
                <section class="card-glass rounded-xl p-6">
                    <h2 class="text-2xl font-bold text-white mb-6 flex items-center gap-2">
                        <i class="fas fa-certificate text-[#58a6ff]"></i>
                        <span>Certifications</span>
                    </h2>
                    
                    <div class="space-y-4">
                        <div class="flex items-center gap-3">
                            <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/2/2e/Offensive_Security_Logo.svg/1200px-Offensive_Security_Logo.svg.png" alt="OSCP" class="w-10 h-10 object-contain">
                            <div>
                                <p class="font-medium text-white">OSCP</p>
                                <p class="text-sm text-gray-400">Offensive Security</p>
                            </div>
                        </div>
                        
                        <div class="flex items-center gap-3">
                            <img src="https://www.isc2.org/-/media/ISC2/Images/Partner-Resources/Partner-Badges/cissp-badge.ashx" alt="CISSP" class="w-10 h-10 object-contain">
                            <div>
                                <p class="font-medium text-white">CISSP</p>
                                <p class="text-sm text-gray-400">(ISC)²</p>
                            </div>
                        </div>
                        
                        <div class="flex items-center gap-3">
                            <img src="https://www.sans.org/wp-content/uploads/20210219134414/GIAC-Certification-Logo-1.png" alt="GWAPT" class="w-10 h-10 object-contain">
                            <div>
                                <p class="font-medium text-white">GWAPT</p>
                                <p class="text-sm text-gray-400">SANS GIAC</p>
                            </div>
                        </div>
                    </div>
                </section>
                
                <!-- Contact -->
                <section class="card-glass rounded-xl p-6">
                    <h2 class="text-2xl font-bold text-white mb-6 flex items-center gap-2">
                        <i class="fas fa-paper-plane text-[#58a6ff]"></i>
                        <span>Contact</span>
                    </h2>
                    
                    <div class="space-y-3">
                        <a href="#" class="flex items-center gap-3 text-gray-300 hover:text-white transition-colors">
                            <i class="fab fa-twitter text-[#1da1f2]"></i>
                            <span>@security_researcher</span>
                        </a>
                        <a href="#" class="flex items-center gap-3 text-gray-300 hover:text-white transition-colors">
                            <i class="fab fa-linkedin text-[#0a66c2]"></i>
                            <span>linkedin.com/in/security-expert</span>
                        </a>
                        <a href="#" class="flex items-center gap-3 text-gray-300 hover:text-white transition-colors">
                            <i class="fas fa-globe text-[#8a63ff]"></i>
                            <span>security-researcher.io</span>
                        </a>
                        <a href="#" class="flex items-center gap-3 text-gray-300 hover:text-white transition-colors">
                            <i class="fas fa-envelope text-[#db61a2]"></i>
                            <span>researcher@protonmail.com</span>
                        </a>
                    </div>
                </section>
            </div>
        </main>
        
        <!-- Footer -->
        <footer class="mt-16 pt-8 border-t border-gray-800 text-center text-gray-400">
            <p>© 2023 Security Researcher. All rights reserved.</p>
            <p class="mt-2 text-sm">"Security is not a product, but a process." - Bruce Schneier</p>
        </footer>
    </div>
</body>
</html>
