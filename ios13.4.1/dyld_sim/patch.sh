#!/bin/sh

# 64-bit

printf "\x8C" | dd of=dyld_sim obs=1 seek=$((0x6814)) conv=notrunc	# Change JB to JL for isSimulatorBinary
printf "\x90\x90\x90\x90\x90\x90" | dd of=dyld_sim obs=1 seek=$((0x34BC)) conv=notrunc  # Change isCompatibleMachO in loadPhase6
printf "\x90\x90\x90\x90\x90\x90" | dd of=dyld_sim obs=1 seek=$((0x34CB)) conv=notrunc  # Same as above line
printf "%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b" \
       "\x53"                      `#push rbx ` \
       "\x4D\x33\xC0"              `#xor r8, r8 ` \
       "\x8B\x4F\x04"              `#mov ecx, dword ptr [rdi+4] ` \
       "\x0F\xC9"                  `#bswap ecx ` \
       "\x48\x83\xC7\x08"          `#add rdi, 8 ` \
`#start:` \
       "\x85\xC9"                  `#test ecx, ecx ` \
       "\x74\x35"                  `#jz end ` \
       "\x8B\x07"                  `#mov eax, dword ptr [rdi] ` \
       "\x3D\x1\x0\x0\x7"          `#cmp eax\x7000001 ` \
       "\x74\x07"                  `#jz next ` \
       "\x3D\x1\x0\x0\x0C"         `#cmp eax\xC000001 ` \
       "\x75\x1D"                  `#jnz next2 ` \
`#next:` \
       "\x8B\x5F\x08"              `#mov ebx, dword ptr [rdi+8] ` \
       "\x0F\xCB"                  `#bswap ebx ` \
       "\x48\x89\x1E"              `#mov qword ptr [rsi], rbx ` \
       "\x8B\x5F\x0C"              `#mov ebx, dword ptr [rdi+0x0C] ` \
       "\x0F\xCB"                  `#bswap ebx ` \
       "\x48\x89\x1A"              `#mov qword ptr [rdx], rbx ` \
       "\x41\xB8\x1\x0\x0\x0"      `#mov r8d, 1 ` \
       "\x3D\x1\x0\x0\x7"          `#cmp eax\x7000001 ` \
       "\x74\x08"                  `#je end ` \
`#next2:` \
       "\x48\x83\xC7\x14"          `#add, rdi\x14 ` \
       "\xFF\xC9"                  `#dec ecx ` \
       "\xEB\xC7"                  `#jmp start ` \
`#end:` \
       "\x41\x8B\xC0"              `#mov eax, r8d ` \
       "\x5B"                      `#pop rbx ` \
       "\xC3"                      `#retn ` \
       | dd of=dyld_sim obs=1 seek=$((0x37BC)) conv=notrunc


printf "\x55\x16\x0\x0" | dd of=dyld_sim obs=1 seek=$((0x5589)) conv=notrunc # assign my_libraryLocator to gLinkContext.loadLibrary
# static ImageLoader* libraryLocator(const char* libraryName, bool search, const char* origin, const ImageLoader::RPathChain* rpaths, unsigned& cacheIndex);
printf "%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b%b" \
       "\x49\x8B\x44\x24\x50"             `#0x0 #mov rax, qword ptr [r12+0x50] // see ImageLoaderMachO:machHeader(), r12 is the leaked this pointer from ImageLoader::recursiveLoadLibraries ` \
       "\x8B\x40\x04"                     `#0x5 #mov eax, dword ptr [rax+4] // cputype of struct mach_header_64 ` \
       "\x3D\x0C\x0\x0\x1"                `#0x8 #cmp eax, 0x0100000C // CPU_TYPE_ARM64 ` \
       "\x0F\x85\x8b\x15\x0\x0"           `#0xd #jnz libraryLocator ` \
       "\x56"                             `#0x13 #push rsi ` \
       "\x52"                             `#0x14 #push rdx ` \
       "\x51"                             `#0x15 #push rcx ` \
       "\x41\x50"                         `#0x16 #push r8 `  \
       "\x57"                             `#0x18 #push rdi // save all the parameters ` \
       "\x48\x8D\x35\x87\x0\x0\x0"        `#0x19 #lea rsi, qword ptr ['/usr/lib/libc++'] ` \
       "\xBA\x0F\x0\x0\x0"                `#0x20 #mov edx, 0xF ` \
       "\xE8\x86\xf0\x1\x0"               `#0x25 #call strncmp ` \
       "\x74\x22"                         `#0x2a #je next ` \
       "\x48\x8B\x3C\x24"                 `#0x2c #mov rdi, qword ptr [rsp] ` \
       "\x48\x8D\x35\x80\x0\x0\x0"        `#0x30 #lea rsi, qword ptr ['/usr/lib/swift/'] ` \
       "\xBA\x0F\x0\x0\x0"                `#0x37 #mov edx, 0xF ` \
       "\xE8\x6f\xf0\x1\x0"               `#0x3c #call strncmp ` \
       "\x74\x0B"                         `#0x41 #je next ` \
       "\x5F"                             `#0x43 #pop rdi ` \
       "\x41\x58"                         `#0x44 #pop r8 ` \
       "\x59"                             `#0x46 #pop rcx ` \
       "\x5A"                             `#0x47 #pop rdx ` \
       "\x5E"                             `#0x48 #pop rsi ` \
       "\xE9\x50\x15\x0\x0"               `#0x49 #jmp libraryLocator ` \
`#next:` \
       "\x48\x81\xEC\x58\x2\x0\x0"        `#0x4e #sub rsp, 0x258 // That's more than enough ` \
       "\x48\xB8\x2F\x41\x52\x4D\x36\x34\x0\x0"  `#0x55 #mov rax, 0x34364D52412F // That's "/ARM64" ` \
       "\x50"                             `#0x5f #push rax // Extra 8 bytes is here ` \
       "\x48\x8D\x7C\x24\x6"              `#0x60 #lea rdi, qword ptr [rsp+6] // 6 is the length of "/ARM64" ` \
       "\x48\x8B\xB4\x24\x60\x2\x0\x0"    `#0x65 #mov rsi, qword ptr [rsp+0x260] // rdi, the original path ` \
       "\xE8\x08\xf1\x1\x0"               `#0x6d #call strcpy ` \
       "\x48\x8B\xFC"                     `#0x72 #mov rdi, rsp ` \
       "\x48\x8B\xB4\x24\x80\x2\x0\x0"    `#0x75 #mov rsi, qword ptr [rsp+0x280] ` \
       "\x48\x8B\x94\x24\x78\x2\x0\x0"    `#0x7d #mov rdx, qword ptr [rsp+0x278] ` \
       "\x48\x8B\x8C\x24\x70\x2\x0\x0"    `#0x85 #mov rcx, qword ptr [rsp+0x270] ` \
       "\x4C\x8B\x84\x24\x68\x2\x0\x0"    `#0x8d #mov r8, qword ptr [rsp+0x268] // restore all the parameters, except for rdi ` \
       "\xE8\x04\x15\x0\x0"               `#0x95 #call libraryLocator ` \
       "\x48\x81\xC4\x88\x2\x0\x0"        `#0x9a #add rsp, 0x288 // Parameters in the stack added ` \
       "\xC3"                             `#0xa1 #ret ` \
       "\x90\x90\x90\x90\x90"             `#0xa2 #alignment ` \
       "\x2F\x75\x73\x72\x2F\x6C\x69\x62\x2F\x6C\x69\x62\x63\x2B\x2B\x0"     `#0xa7 #"/usr/lib/libc++" ` \
       "\x2F\x75\x73\x72\x2F\x6C\x69\x62\x2F\x73\x77\x69\x66\x74\x2F\x0"     `#0xb7 #"/usr/lib/swift/" ` \
       | dd of=dyld_sim obs=1 seek=$((0x6be2)) conv=notrunc
