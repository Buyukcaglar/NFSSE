Static x86 excerpts; VA uses image base 0x00400000.
FILE offsets refer to the original executable.
Labels are analyst descriptions, not recovered symbols.

; Entry jump: VA 0x0048C802 to 0x0048C807 (end exclusive)
FILE 0008BC02  VA 0048C802  e9 7b 5a 01 00               jmp      0x4a2282

; Watcom startup: VA 0x004A2282 to 0x004A22C8 (end exclusive)
FILE 000A1682  VA 004A2282  53                           push     ebx
FILE 000A1683  VA 004A2283  51                           push     ecx
FILE 000A1684  VA 004A2284  52                           push     edx
FILE 000A1685  VA 004A2285  55                           push     ebp
FILE 000A1686  VA 004A2286  89 e5                        mov      ebp, esp
FILE 000A1688  VA 004A2288  83 ec 08                     sub      esp, 8
FILE 000A168B  VA 004A228B  b8 01 00 00 00               mov      eax, 1
FILE 000A1690  VA 004A2290  e8 5b 50 00 00               call     0x4a72f0
FILE 000A1695  VA 004A2295  a1 a0 6c 4f 00               mov      eax, dword ptr [0x4f6ca0]
FILE 000A169A  VA 004A229A  83 c0 03                     add      eax, 3
FILE 000A169D  VA 004A229D  24 fc                        and      al, 0xfc
FILE 000A169F  VA 004A229F  31 d2                        xor      edx, edx
FILE 000A16A1  VA 004A22A1  29 c4                        sub      esp, eax
FILE 000A16A3  VA 004A22A3  89 e1                        mov      ecx, esp
FILE 000A16A5  VA 004A22A5  8b 1d a0 6c 4f 00            mov      ebx, dword ptr [0x4f6ca0]
FILE 000A16AB  VA 004A22AB  89 c8                        mov      eax, ecx
FILE 000A16AD  VA 004A22AD  e8 de 45 00 00               call     0x4a6890
FILE 000A16B2  VA 004A22B2  8d 45 f8                     lea      eax, [ebp - 8]
FILE 000A16B5  VA 004A22B5  89 ca                        mov      edx, ecx
FILE 000A16B7  VA 004A22B7  e8 37 cc ff ff               call     0x49eef3
FILE 000A16BC  VA 004A22BC  e8 2a 5f 00 00               call     0x4a81eb
FILE 000A16C1  VA 004A22C1  89 ec                        mov      esp, ebp
FILE 000A16C3  VA 004A22C3  5d                           pop      ebp
FILE 000A16C4  VA 004A22C4  5a                           pop      edx
FILE 000A16C5  VA 004A22C5  59                           pop      ecx
FILE 000A16C6  VA 004A22C6  5b                           pop      ebx
FILE 000A16C7  VA 004A22C7  c3                           ret

; nfs.cfg parser: VA 0x00432144 to 0x004322F8 (end exclusive)
FILE 00031544  VA 00432144  56                           push     esi
FILE 00031545  VA 00432145  57                           push     edi
FILE 00031546  VA 00432146  55                           push     ebp
FILE 00031547  VA 00432147  83 ec 70                     sub      esp, 0x70
FILE 0003154A  VA 0043214A  89 44 24 68                  mov      dword ptr [esp + 0x68], eax
FILE 0003154E  VA 0043214E  89 d5                        mov      ebp, edx
FILE 00031550  VA 00432150  89 5c 24 64                  mov      dword ptr [esp + 0x64], ebx
FILE 00031554  VA 00432154  89 4c 24 6c                  mov      dword ptr [esp + 0x6c], ecx
FILE 00031558  VA 00432158  ba b0 f4 4a 00               mov      edx, 0x4af4b0
FILE 0003155D  VA 0043215D  b8 b4 f4 4a 00               mov      eax, 0x4af4b4
FILE 00031562  VA 00432162  e8 67 00 05 00               call     0x4821ce
FILE 00031567  VA 00432167  31 c9                        xor      ecx, ecx
FILE 00031569  VA 00432169  31 f6                        xor      esi, esi
FILE 0003156B  VA 0043216B  89 c7                        mov      edi, eax
FILE 0003156D  VA 0043216D  85 c0                        test     eax, eax
FILE 0003156F  VA 0043216F  75 16                        jne      0x432187
FILE 00031571  VA 00432171  8b 44 24 68                  mov      eax, dword ptr [esp + 0x68]
FILE 00031575  VA 00432175  89 38                        mov      dword ptr [eax], edi
FILE 00031577  VA 00432177  89 7d 00                     mov      dword ptr [ebp], edi
FILE 0003157A  VA 0043217A  8b 44 24 6c                  mov      eax, dword ptr [esp + 0x6c]
FILE 0003157E  VA 0043217E  89 3b                        mov      dword ptr [ebx], edi
FILE 00031580  VA 00432180  89 38                        mov      dword ptr [eax], edi
FILE 00031582  VA 00432182  e9 6a 01 00 00               jmp      0x4322f1
FILE 00031587  VA 00432187  ba 50 00 00 00               mov      edx, 0x50
FILE 0003158C  VA 0043218C  89 c3                        mov      ebx, eax
FILE 0003158E  VA 0043218E  89 e0                        mov      eax, esp
FILE 00031590  VA 00432190  e8 25 01 05 00               call     0x4822ba
FILE 00031595  VA 00432195  89 f8                        mov      eax, edi
FILE 00031597  VA 00432197  e8 99 01 05 00               call     0x482335
FILE 0003159C  VA 0043219C  8a 04 24                     mov      al, byte ptr [esp]
FILE 0003159F  VA 0043219F  88 44 24 50                  mov      byte ptr [esp + 0x50], al
FILE 000315A3  VA 004321A3  0f bf c6                     movsx    eax, si
FILE 000315A6  VA 004321A6  80 7c 04 50 20               cmp      byte ptr [esp + eax + 0x50], 0x20
FILE 000315AB  VA 004321AB  74 11                        je       0x4321be
FILE 000315AD  VA 004321AD  41                           inc      ecx
FILE 000315AE  VA 004321AE  46                           inc      esi
FILE 000315AF  VA 004321AF  0f bf c1                     movsx    eax, cx
FILE 000315B2  VA 004321B2  0f bf de                     movsx    ebx, si
FILE 000315B5  VA 004321B5  8a 04 04                     mov      al, byte ptr [esp + eax]
FILE 000315B8  VA 004321B8  88 44 1c 50                  mov      byte ptr [esp + ebx + 0x50], al
FILE 000315BC  VA 004321BC  eb e5                        jmp      0x4321a3
FILE 000315BE  VA 004321BE  30 f6                        xor      dh, dh
FILE 000315C0  VA 004321C0  88 74 04 50                  mov      byte ptr [esp + eax + 0x50], dh
FILE 000315C4  VA 004321C4  ba bc f4 4a 00               mov      edx, 0x4af4bc
FILE 000315C9  VA 004321C9  8d 44 24 50                  lea      eax, [esp + 0x50]
FILE 000315CD  VA 004321CD  41                           inc      ecx
FILE 000315CE  VA 004321CE  e8 bd 40 04 00               call     0x476290
FILE 000315D3  VA 004321D3  85 c0                        test     eax, eax
FILE 000315D5  VA 004321D5  0f 95 c0                     setne    al
FILE 000315D8  VA 004321D8  25 ff 00 00 00               and      eax, 0xff
FILE 000315DD  VA 004321DD  8b 5c 24 68                  mov      ebx, dword ptr [esp + 0x68]
FILE 000315E1  VA 004321E1  48                           dec      eax
FILE 000315E2  VA 004321E2  89 03                        mov      dword ptr [ebx], eax
FILE 000315E4  VA 004321E4  0f bf c1                     movsx    eax, cx
FILE 000315E7  VA 004321E7  8a 04 04                     mov      al, byte ptr [esp + eax]
FILE 000315EA  VA 004321EA  31 d2                        xor      edx, edx
FILE 000315EC  VA 004321EC  88 44 24 50                  mov      byte ptr [esp + 0x50], al
FILE 000315F0  VA 004321F0  0f bf c2                     movsx    eax, dx
FILE 000315F3  VA 004321F3  80 7c 04 50 20               cmp      byte ptr [esp + eax + 0x50], 0x20
FILE 000315F8  VA 004321F8  74 11                        je       0x43220b
FILE 000315FA  VA 004321FA  41                           inc      ecx
FILE 000315FB  VA 004321FB  42                           inc      edx
FILE 000315FC  VA 004321FC  0f bf c1                     movsx    eax, cx
FILE 000315FF  VA 004321FF  0f bf f2                     movsx    esi, dx
FILE 00031602  VA 00432202  8a 04 04                     mov      al, byte ptr [esp + eax]
FILE 00031605  VA 00432205  88 44 34 50                  mov      byte ptr [esp + esi + 0x50], al
FILE 00031609  VA 00432209  eb e5                        jmp      0x4321f0
FILE 0003160B  VA 0043220B  30 ff                        xor      bh, bh
FILE 0003160D  VA 0043220D  ba c8 f4 4a 00               mov      edx, 0x4af4c8
FILE 00031612  VA 00432212  88 7c 04 50                  mov      byte ptr [esp + eax + 0x50], bh
FILE 00031616  VA 00432216  8d 44 24 50                  lea      eax, [esp + 0x50]
FILE 0003161A  VA 0043221A  41                           inc      ecx
FILE 0003161B  VA 0043221B  e8 70 40 04 00               call     0x476290
FILE 00031620  VA 00432220  85 c0                        test     eax, eax
FILE 00031622  VA 00432222  75 05                        jne      0x432229
FILE 00031624  VA 00432224  89 45 00                     mov      dword ptr [ebp], eax
FILE 00031627  VA 00432227  eb 22                        jmp      0x43224b
FILE 00031629  VA 00432229  ba d0 f4 4a 00               mov      edx, 0x4af4d0
FILE 0003162E  VA 0043222E  8d 44 24 50                  lea      eax, [esp + 0x50]
FILE 00031632  VA 00432232  e8 59 40 04 00               call     0x476290
FILE 00031637  VA 00432237  85 c0                        test     eax, eax
FILE 00031639  VA 00432239  75 09                        jne      0x432244
FILE 0003163B  VA 0043223B  c7 45 00 01 00 00 00         mov      dword ptr [ebp], 1
FILE 00031642  VA 00432242  eb 07                        jmp      0x43224b
FILE 00031644  VA 00432244  c7 45 00 02 00 00 00         mov      dword ptr [ebp], 2
FILE 0003164B  VA 0043224B  0f bf c1                     movsx    eax, cx
FILE 0003164E  VA 0043224E  8a 04 04                     mov      al, byte ptr [esp + eax]
FILE 00031651  VA 00432251  31 d2                        xor      edx, edx
FILE 00031653  VA 00432253  88 44 24 50                  mov      byte ptr [esp + 0x50], al
FILE 00031657  VA 00432257  0f bf c2                     movsx    eax, dx
FILE 0003165A  VA 0043225A  80 7c 04 50 20               cmp      byte ptr [esp + eax + 0x50], 0x20
FILE 0003165F  VA 0043225F  74 11                        je       0x432272
FILE 00031661  VA 00432261  41                           inc      ecx
FILE 00031662  VA 00432262  42                           inc      edx
FILE 00031663  VA 00432263  0f bf c1                     movsx    eax, cx
FILE 00031666  VA 00432266  0f bf da                     movsx    ebx, dx
FILE 00031669  VA 00432269  8a 04 04                     mov      al, byte ptr [esp + eax]
FILE 0003166C  VA 0043226C  88 44 1c 50                  mov      byte ptr [esp + ebx + 0x50], al
FILE 00031670  VA 00432270  eb e5                        jmp      0x432257
FILE 00031672  VA 00432272  30 ff                        xor      bh, bh
FILE 00031674  VA 00432274  ba dc f4 4a 00               mov      edx, 0x4af4dc
FILE 00031679  VA 00432279  88 7c 04 50                  mov      byte ptr [esp + eax + 0x50], bh
FILE 0003167D  VA 0043227D  8d 44 24 50                  lea      eax, [esp + 0x50]
FILE 00031681  VA 00432281  41                           inc      ecx
FILE 00031682  VA 00432282  e8 09 40 04 00               call     0x476290
FILE 00031687  VA 00432287  85 c0                        test     eax, eax
FILE 00031689  VA 00432289  0f 94 c0                     sete     al
FILE 0003168C  VA 0043228C  8b 5c 24 64                  mov      ebx, dword ptr [esp + 0x64]
FILE 00031690  VA 00432290  25 ff 00 00 00               and      eax, 0xff
FILE 00031695  VA 00432295  89 03                        mov      dword ptr [ebx], eax
FILE 00031697  VA 00432297  0f bf c1                     movsx    eax, cx
FILE 0003169A  VA 0043229A  8a 04 04                     mov      al, byte ptr [esp + eax]
FILE 0003169D  VA 0043229D  31 d2                        xor      edx, edx
FILE 0003169F  VA 0043229F  88 44 24 50                  mov      byte ptr [esp + 0x50], al
FILE 000316A3  VA 004322A3  0f bf c2                     movsx    eax, dx
FILE 000316A6  VA 004322A6  80 7c 04 50 20               cmp      byte ptr [esp + eax + 0x50], 0x20
FILE 000316AB  VA 004322AB  74 11                        je       0x4322be
FILE 000316AD  VA 004322AD  41                           inc      ecx
FILE 000316AE  VA 004322AE  42                           inc      edx
FILE 000316AF  VA 004322AF  0f bf c1                     movsx    eax, cx
FILE 000316B2  VA 004322B2  0f bf da                     movsx    ebx, dx
FILE 000316B5  VA 004322B5  8a 04 04                     mov      al, byte ptr [esp + eax]
FILE 000316B8  VA 004322B8  88 44 1c 50                  mov      byte ptr [esp + ebx + 0x50], al
FILE 000316BC  VA 004322BC  eb e5                        jmp      0x4322a3
FILE 000316BE  VA 004322BE  30 ff                        xor      bh, bh
FILE 000316C0  VA 004322C0  ba e4 f4 4a 00               mov      edx, 0x4af4e4
FILE 000316C5  VA 004322C5  88 7c 04 50                  mov      byte ptr [esp + eax + 0x50], bh
FILE 000316C9  VA 004322C9  8d 44 24 50                  lea      eax, [esp + 0x50]
FILE 000316CD  VA 004322CD  e8 be 3f 04 00               call     0x476290
FILE 000316D2  VA 004322D2  85 c0                        test     eax, eax
FILE 000316D4  VA 004322D4  75 11                        jne      0x4322e7
FILE 000316D6  VA 004322D6  8b 44 24 6c                  mov      eax, dword ptr [esp + 0x6c]
FILE 000316DA  VA 004322DA  c7 00 00 00 00 00            mov      dword ptr [eax], 0
FILE 000316E0  VA 004322E0  83 c4 70                     add      esp, 0x70
FILE 000316E3  VA 004322E3  5d                           pop      ebp
FILE 000316E4  VA 004322E4  5f                           pop      edi
FILE 000316E5  VA 004322E5  5e                           pop      esi
FILE 000316E6  VA 004322E6  c3                           ret
FILE 000316E7  VA 004322E7  8b 44 24 6c                  mov      eax, dword ptr [esp + 0x6c]
FILE 000316EB  VA 004322EB  c7 00 01 00 00 00            mov      dword ptr [eax], 1
FILE 000316F1  VA 004322F1  83 c4 70                     add      esp, 0x70
FILE 000316F4  VA 004322F4  5d                           pop      ebp
FILE 000316F5  VA 004322F5  5f                           pop      edi
FILE 000316F6  VA 004322F6  5e                           pop      esi
FILE 000316F7  VA 004322F7  c3                           ret

; paths.dat loader and CD gates: VA 0x0042A188 to 0x0042A483 (end exclusive)
FILE 00029588  VA 0042A188  53                           push     ebx
FILE 00029589  VA 0042A189  51                           push     ecx
FILE 0002958A  VA 0042A18A  52                           push     edx
FILE 0002958B  VA 0042A18B  56                           push     esi
FILE 0002958C  VA 0042A18C  57                           push     edi
FILE 0002958D  VA 0042A18D  55                           push     ebp
FILE 0002958E  VA 0042A18E  81 ec ac 00 00 00            sub      esp, 0xac
FILE 00029594  VA 0042A194  68 4c ec 4a 00               push     0x4aec4c
FILE 00029599  VA 0042A199  8d 44 24 04                  lea      eax, [esp + 4]
FILE 0002959D  VA 0042A19D  50                           push     eax
FILE 0002959E  VA 0042A19E  e8 a0 9b 04 00               call     0x473d43
FILE 000295A3  VA 0042A1A3  83 c4 08                     add      esp, 8
FILE 000295A6  VA 0042A1A6  8d 84 24 a4 00 00 00         lea      eax, [esp + 0xa4]
FILE 000295AD  VA 0042A1AD  50                           push     eax
FILE 000295AE  VA 0042A1AE  8d 84 24 a4 00 00 00         lea      eax, [esp + 0xa4]
FILE 000295B5  VA 0042A1B5  50                           push     eax
FILE 000295B6  VA 0042A1B6  8d 84 24 b0 00 00 00         lea      eax, [esp + 0xb0]
FILE 000295BD  VA 0042A1BD  50                           push     eax
FILE 000295BE  VA 0042A1BE  8d 44 24 0c                  lea      eax, [esp + 0xc]
FILE 000295C2  VA 0042A1C2  31 d2                        xor      edx, edx
FILE 000295C4  VA 0042A1C4  50                           push     eax
FILE 000295C5  VA 0042A1C5  89 94 24 b0 00 00 00         mov      dword ptr [esp + 0xb0], edx
FILE 000295CC  VA 0042A1CC  e8 57 e2 05 00               call     0x488428
FILE 000295D1  VA 0042A1D1  83 c4 10                     add      esp, 0x10
FILE 000295D4  VA 0042A1D4  83 bc 24 a8 00 00 00 00      cmp      dword ptr [esp + 0xa8], 0
FILE 000295DC  VA 0042A1DC  0f 85 de 01 00 00            jne      0x42a3c0
FILE 000295E2  VA 0042A1E2  66 83 3d cc 5c 4c 00 00      cmp      word ptr [0x4c5ccc], 0
FILE 000295EA  VA 0042A1EA  0f 85 80 02 00 00            jne      0x42a470
FILE 000295F0  VA 0042A1F0  68 68 ec 4a 00               push     0x4aec68
FILE 000295F5  VA 0042A1F5  68 98 41 52 00               push     0x524198
FILE 000295FA  VA 0042A1FA  e8 44 9b 04 00               call     0x473d43
FILE 000295FF  VA 0042A1FF  83 c4 08                     add      esp, 8
FILE 00029602  VA 0042A202  68 7c ec 4a 00               push     0x4aec7c
FILE 00029607  VA 0042A207  68 e8 41 52 00               push     0x5241e8
FILE 0002960C  VA 0042A20C  e8 32 9b 04 00               call     0x473d43
FILE 00029611  VA 0042A211  83 c4 08                     add      esp, 8
FILE 00029614  VA 0042A214  68 90 ec 4a 00               push     0x4aec90
FILE 00029619  VA 0042A219  68 18 44 52 00               push     0x524418
FILE 0002961E  VA 0042A21E  e8 20 9b 04 00               call     0x473d43
FILE 00029623  VA 0042A223  83 c4 08                     add      esp, 8
FILE 00029626  VA 0042A226  68 a4 ec 4a 00               push     0x4aeca4
FILE 0002962B  VA 0042A22B  68 78 43 52 00               push     0x524378
FILE 00029630  VA 0042A230  e8 0e 9b 04 00               call     0x473d43
FILE 00029635  VA 0042A235  83 c4 08                     add      esp, 8
FILE 00029638  VA 0042A238  68 b4 ec 4a 00               push     0x4aecb4
FILE 0002963D  VA 0042A23D  68 c8 43 52 00               push     0x5243c8
FILE 00029642  VA 0042A242  e8 fc 9a 04 00               call     0x473d43
FILE 00029647  VA 0042A247  83 c4 08                     add      esp, 8
FILE 0002964A  VA 0042A24A  68 c4 ec 4a 00               push     0x4aecc4
FILE 0002964F  VA 0042A24F  68 d8 42 52 00               push     0x5242d8
FILE 00029654  VA 0042A254  e8 ea 9a 04 00               call     0x473d43
FILE 00029659  VA 0042A259  83 c4 08                     add      esp, 8
FILE 0002965C  VA 0042A25C  68 d4 ec 4a 00               push     0x4aecd4
FILE 00029661  VA 0042A261  68 88 42 52 00               push     0x524288
FILE 00029666  VA 0042A266  e8 d8 9a 04 00               call     0x473d43
FILE 0002966B  VA 0042A26B  83 c4 08                     add      esp, 8
FILE 0002966E  VA 0042A26E  68 e8 ec 4a 00               push     0x4aece8
FILE 00029673  VA 0042A273  68 48 46 52 00               push     0x524648
FILE 00029678  VA 0042A278  e8 c6 9a 04 00               call     0x473d43
FILE 0002967D  VA 0042A27D  83 c4 08                     add      esp, 8
FILE 00029680  VA 0042A280  68 fc ec 4a 00               push     0x4aecfc
FILE 00029685  VA 0042A285  68 68 44 52 00               push     0x524468
FILE 0002968A  VA 0042A28A  e8 b4 9a 04 00               call     0x473d43
FILE 0002968F  VA 0042A28F  83 c4 08                     add      esp, 8
FILE 00029692  VA 0042A292  68 0c ed 4a 00               push     0x4aed0c
FILE 00029697  VA 0042A297  68 a8 45 52 00               push     0x5245a8
FILE 0002969C  VA 0042A29C  e8 a2 9a 04 00               call     0x473d43
FILE 000296A1  VA 0042A2A1  83 c4 08                     add      esp, 8
FILE 000296A4  VA 0042A2A4  68 20 ed 4a 00               push     0x4aed20
FILE 000296A9  VA 0042A2A9  68 f8 45 52 00               push     0x5245f8
FILE 000296AE  VA 0042A2AE  e8 90 9a 04 00               call     0x473d43
FILE 000296B3  VA 0042A2B3  83 c4 08                     add      esp, 8
FILE 000296B6  VA 0042A2B6  68 fc ec 4a 00               push     0x4aecfc
FILE 000296BB  VA 0042A2BB  68 e8 46 52 00               push     0x5246e8
FILE 000296C0  VA 0042A2C0  e8 7e 9a 04 00               call     0x473d43
FILE 000296C5  VA 0042A2C5  66 8b 35 1c b3 52 00         mov      si, word ptr [0x52b31c]
FILE 000296CC  VA 0042A2CC  83 c4 08                     add      esp, 8
FILE 000296CF  VA 0042A2CF  66 85 f6                     test     si, si
FILE 000296D2  VA 0042A2D2  74 61                        je       0x42a335
FILE 000296D4  VA 0042A2D4  68 34 ed 4a 00               push     0x4aed34
FILE 000296D9  VA 0042A2D9  68 38 42 52 00               push     0x524238
FILE 000296DE  VA 0042A2DE  e8 60 9a 04 00               call     0x473d43
FILE 000296E3  VA 0042A2E3  83 c4 08                     add      esp, 8
FILE 000296E6  VA 0042A2E6  68 48 ed 4a 00               push     0x4aed48
FILE 000296EB  VA 0042A2EB  68 28 43 52 00               push     0x524328
FILE 000296F0  VA 0042A2F0  e8 4e 9a 04 00               call     0x473d43
FILE 000296F5  VA 0042A2F5  83 c4 08                     add      esp, 8
FILE 000296F8  VA 0042A2F8  68 58 ed 4a 00               push     0x4aed58
FILE 000296FD  VA 0042A2FD  68 38 47 52 00               push     0x524738
FILE 00029702  VA 0042A302  e8 3c 9a 04 00               call     0x473d43
FILE 00029707  VA 0042A307  83 c4 08                     add      esp, 8
FILE 0002970A  VA 0042A30A  68 68 ed 4a 00               push     0x4aed68
FILE 0002970F  VA 0042A30F  68 58 45 52 00               push     0x524558
FILE 00029714  VA 0042A314  e8 2a 9a 04 00               call     0x473d43
FILE 00029719  VA 0042A319  83 c4 08                     add      esp, 8
FILE 0002971C  VA 0042A31C  68 7c ed 4a 00               push     0x4aed7c
FILE 00029721  VA 0042A321  68 b8 44 52 00               push     0x5244b8
FILE 00029726  VA 0042A326  e8 18 9a 04 00               call     0x473d43
FILE 0002972B  VA 0042A32B  83 c4 08                     add      esp, 8
FILE 0002972E  VA 0042A32E  68 90 ed 4a 00               push     0x4aed90
FILE 00029733  VA 0042A333  eb 5f                        jmp      0x42a394
FILE 00029735  VA 0042A335  68 a0 ed 4a 00               push     0x4aeda0
FILE 0002973A  VA 0042A33A  68 38 42 52 00               push     0x524238
FILE 0002973F  VA 0042A33F  e8 ff 99 04 00               call     0x473d43
FILE 00029744  VA 0042A344  83 c4 08                     add      esp, 8
FILE 00029747  VA 0042A347  68 b4 ed 4a 00               push     0x4aedb4
FILE 0002974C  VA 0042A34C  68 28 43 52 00               push     0x524328
FILE 00029751  VA 0042A351  e8 ed 99 04 00               call     0x473d43
FILE 00029756  VA 0042A356  83 c4 08                     add      esp, 8
FILE 00029759  VA 0042A359  68 c4 ed 4a 00               push     0x4aedc4
FILE 0002975E  VA 0042A35E  68 38 47 52 00               push     0x524738
FILE 00029763  VA 0042A363  e8 db 99 04 00               call     0x473d43
FILE 00029768  VA 0042A368  83 c4 08                     add      esp, 8
FILE 0002976B  VA 0042A36B  68 d4 ed 4a 00               push     0x4aedd4
FILE 00029770  VA 0042A370  68 58 45 52 00               push     0x524558
FILE 00029775  VA 0042A375  e8 c9 99 04 00               call     0x473d43
FILE 0002977A  VA 0042A37A  83 c4 08                     add      esp, 8
FILE 0002977D  VA 0042A37D  68 e4 ed 4a 00               push     0x4aede4
FILE 00029782  VA 0042A382  68 b8 44 52 00               push     0x5244b8
FILE 00029787  VA 0042A387  e8 b7 99 04 00               call     0x473d43
FILE 0002978C  VA 0042A38C  83 c4 08                     add      esp, 8
FILE 0002978F  VA 0042A38F  68 f8 ed 4a 00               push     0x4aedf8
FILE 00029794  VA 0042A394  68 98 46 52 00               push     0x524698
FILE 00029799  VA 0042A399  e8 a5 99 04 00               call     0x473d43
FILE 0002979E  VA 0042A39E  83 c4 08                     add      esp, 8
FILE 000297A1  VA 0042A3A1  68 08 ee 4a 00               push     0x4aee08
FILE 000297A6  VA 0042A3A6  68 08 45 52 00               push     0x524508
FILE 000297AB  VA 0042A3AB  e8 93 99 04 00               call     0x473d43
FILE 000297B0  VA 0042A3B0  83 c4 08                     add      esp, 8
FILE 000297B3  VA 0042A3B3  81 c4 ac 00 00 00            add      esp, 0xac
FILE 000297B9  VA 0042A3B9  5d                           pop      ebp
FILE 000297BA  VA 0042A3BA  5f                           pop      edi
FILE 000297BB  VA 0042A3BB  5e                           pop      esi
FILE 000297BC  VA 0042A3BC  5a                           pop      edx
FILE 000297BD  VA 0042A3BD  59                           pop      ecx
FILE 000297BE  VA 0042A3BE  5b                           pop      ebx
FILE 000297BF  VA 0042A3BF  c3                           ret
FILE 000297C0  VA 0042A3C0  6a 00                        push     0
FILE 000297C2  VA 0042A3C2  8b 8c 24 a8 00 00 00         mov      ecx, dword ptr [esp + 0xa8]
FILE 000297C9  VA 0042A3C9  51                           push     ecx
FILE 000297CA  VA 0042A3CA  68 1c ee 4a 00               push     0x4aee1c
FILE 000297CF  VA 0042A3CF  e8 b8 a8 04 00               call     0x474c8c
FILE 000297D4  VA 0042A3D4  83 c4 0c                     add      esp, 0xc
FILE 000297D7  VA 0042A3D7  8b b4 24 a4 00 00 00         mov      esi, dword ptr [esp + 0xa4]
FILE 000297DE  VA 0042A3DE  56                           push     esi
FILE 000297DF  VA 0042A3DF  50                           push     eax
FILE 000297E0  VA 0042A3E0  8b bc 24 b0 00 00 00         mov      edi, dword ptr [esp + 0xb0]
FILE 000297E7  VA 0042A3E7  57                           push     edi
FILE 000297E8  VA 0042A3E8  89 c3                        mov      ebx, eax
FILE 000297EA  VA 0042A3EA  e8 e9 e0 05 00               call     0x4884d8
FILE 000297EF  VA 0042A3EF  83 c4 0c                     add      esp, 0xc
FILE 000297F2  VA 0042A3F2  8b ac 24 a8 00 00 00         mov      ebp, dword ptr [esp + 0xa8]
FILE 000297F9  VA 0042A3F9  55                           push     ebp
FILE 000297FA  VA 0042A3FA  89 de                        mov      esi, ebx
FILE 000297FC  VA 0042A3FC  e8 c7 e0 05 00               call     0x4884c8
FILE 00029801  VA 0042A401  83 c4 04                     add      esp, 4
FILE 00029804  VA 0042A404  bf 98 41 52 00               mov      edi, 0x524198
FILE 00029809  VA 0042A409  b9 f0 05 00 00               mov      ecx, 0x5f0
FILE 0002980E  VA 0042A40E  f3 a4                        rep movsb byte ptr es:[edi], byte ptr [esi]
FILE 00029810  VA 0042A410  53                           push     ebx
FILE 00029811  VA 0042A411  e8 4a ae 04 00               call     0x475260
FILE 00029816  VA 0042A416  66 8b 15 cc 5c 4c 00         mov      dx, word ptr [0x4c5ccc]
FILE 0002981D  VA 0042A41D  83 c4 04                     add      esp, 4
FILE 00029820  VA 0042A420  66 85 d2                     test     dx, dx
FILE 00029823  VA 0042A423  74 51                        je       0x42a476
FILE 00029825  VA 0042A425  66 83 3d 1e b3 52 00 00      cmp      word ptr [0x52b31e], 0
FILE 0002982D  VA 0042A42D  75 47                        jne      0x42a476
FILE 0002982F  VA 0042A42F  68 c8 43 52 00               push     0x5243c8
FILE 00029834  VA 0042A434  a0 c8 43 52 00               mov      al, byte ptr [0x5243c8]
FILE 00029839  VA 0042A439  31 db                        xor      ebx, ebx
FILE 0002983B  VA 0042A43B  68 24 ee 4a 00               push     0x4aee24
FILE 00029840  VA 0042A440  88 c3                        mov      bl, al
FILE 00029842  VA 0042A442  8d 44 24 58                  lea      eax, [esp + 0x58]
FILE 00029846  VA 0042A446  50                           push     eax
FILE 00029847  VA 0042A447  83 eb 41                     sub      ebx, 0x41
FILE 0002984A  VA 0042A44A  e8 f4 98 04 00               call     0x473d43
FILE 0002984F  VA 0042A44F  83 c4 0c                     add      esp, 0xc
FILE 00029852  VA 0042A452  89 d8                        mov      eax, ebx
FILE 00029854  VA 0042A454  e8 53 cf 03 00               call     0x4673ac
FILE 00029859  VA 0042A459  85 c0                        test     eax, eax
FILE 0002985B  VA 0042A45B  75 06                        jne      0x42a463
FILE 0002985D  VA 0042A45D  ff 15 88 6f 4c 00            call     dword ptr [0x4c6f88]
FILE 00029863  VA 0042A463  8d 44 24 50                  lea      eax, [esp + 0x50]
FILE 00029867  VA 0042A467  e8 2c cf 03 00               call     0x467398
FILE 0002986C  VA 0042A46C  85 c0                        test     eax, eax
FILE 0002986E  VA 0042A46E  75 06                        jne      0x42a476
FILE 00029870  VA 0042A470  ff 15 88 6f 4c 00            call     dword ptr [0x4c6f88]
FILE 00029876  VA 0042A476  81 c4 ac 00 00 00            add      esp, 0xac
FILE 0002987C  VA 0042A47C  5d                           pop      ebp
FILE 0002987D  VA 0042A47D  5f                           pop      edi
FILE 0002987E  VA 0042A47E  5e                           pop      esi
FILE 0002987F  VA 0042A47F  5a                           pop      edx
FILE 00029880  VA 0042A480  59                           pop      ecx
FILE 00029881  VA 0042A481  5b                           pop      ebx
FILE 00029882  VA 0042A482  c3                           ret

; title.tgv presence gate and CD errors: VA 0x0043264F to 0x004326D2 (end exclusive)
FILE 00031A4F  VA 0043264F  e8 f0 a0 00 00               call     0x43c744
FILE 00031A54  VA 00432654  e8 ab 1c 03 00               call     0x464304
FILE 00031A59  VA 00432659  e8 4e ed fd ff               call     0x4113ac
FILE 00031A5E  VA 0043265E  e8 d5 56 05 00               call     0x487d38
FILE 00031A63  VA 00432663  66 83 3d 1e b3 52 00 00      cmp      word ptr [0x52b31e], 0
FILE 00031A6B  VA 0043266B  75 65                        jne      0x4326d2
FILE 00031A6D  VA 0043266D  68 c8 43 52 00               push     0x5243c8
FILE 00031A72  VA 00432672  68 8c f7 4a 00               push     0x4af78c
FILE 00031A77  VA 00432677  8d 84 24 e8 04 00 00         lea      eax, [esp + 0x4e8]
FILE 00031A7E  VA 0043267E  50                           push     eax
FILE 00031A7F  VA 0043267F  e8 bf 16 04 00               call     0x473d43
FILE 00031A84  VA 00432684  83 c4 0c                     add      esp, 0xc
FILE 00031A87  VA 00432687  8d 84 24 e0 04 00 00         lea      eax, [esp + 0x4e0]
FILE 00031A8E  VA 0043268E  50                           push     eax
FILE 00031A8F  VA 0043268F  e8 4c 60 05 00               call     0x4886e0
FILE 00031A94  VA 00432694  83 c4 04                     add      esp, 4
FILE 00031A97  VA 00432697  85 c0                        test     eax, eax
FILE 00031A99  VA 00432699  74 13                        je       0x4326ae
FILE 00031A9B  VA 0043269B  8d 84 24 e0 04 00 00         lea      eax, [esp + 0x4e0]
FILE 00031AA2  VA 004326A2  50                           push     eax
FILE 00031AA3  VA 004326A3  50                           push     eax
FILE 00031AA4  VA 004326A4  e8 e7 7f 05 00               call     0x48a690
FILE 00031AA9  VA 004326A9  83 c4 08                     add      esp, 8
FILE 00031AAC  VA 004326AC  eb 24                        jmp      0x4326d2
FILE 00031AAE  VA 004326AE  66 83 3d 1c b3 52 00 00      cmp      word ptr [0x52b31c], 0
FILE 00031AB6  VA 004326B6  74 07                        je       0x4326bf
FILE 00031AB8  VA 004326B8  68 98 f7 4a 00               push     0x4af798
FILE 00031ABD  VA 004326BD  eb 05                        jmp      0x4326c4
FILE 00031ABF  VA 004326BF  68 b0 f7 4a 00               push     0x4af7b0
FILE 00031AC4  VA 004326C4  e8 77 53 04 00               call     0x477a40
FILE 00031AC9  VA 004326C9  83 c4 04                     add      esp, 4
FILE 00031ACC  VA 004326CC  ff 15 88 6f 4c 00            call     dword ptr [0x4c6f88]

; By_R&T writeability check: VA 0x0044028C to 0x00440349 (end exclusive)
FILE 0003F68C  VA 0044028C  66 83 3d cc 5c 4c 00 00      cmp      word ptr [0x4c5ccc], 0
FILE 0003F694  VA 00440294  0f 84 af 00 00 00            je       0x440349
FILE 0003F69A  VA 0044029A  66 83 3d 1e b3 52 00 00      cmp      word ptr [0x52b31e], 0
FILE 0003F6A2  VA 004402A2  0f 85 a1 00 00 00            jne      0x440349
FILE 0003F6A8  VA 004402A8  be 48 46 52 00               mov      esi, 0x524648
FILE 0003F6AD  VA 004402AD  8d bc 24 c8 00 00 00         lea      edi, [esp + 0xc8]
FILE 0003F6B4  VA 004402B4  57                           push     edi
FILE 0003F6B5  VA 004402B5  8a 06                        mov      al, byte ptr [esi]
FILE 0003F6B7  VA 004402B7  88 07                        mov      byte ptr [edi], al
FILE 0003F6B9  VA 004402B9  3c 00                        cmp      al, 0
FILE 0003F6BB  VA 004402BB  74 10                        je       0x4402cd
FILE 0003F6BD  VA 004402BD  8a 46 01                     mov      al, byte ptr [esi + 1]
FILE 0003F6C0  VA 004402C0  83 c6 02                     add      esi, 2
FILE 0003F6C3  VA 004402C3  88 47 01                     mov      byte ptr [edi + 1], al
FILE 0003F6C6  VA 004402C6  83 c7 02                     add      edi, 2
FILE 0003F6C9  VA 004402C9  3c 00                        cmp      al, 0
FILE 0003F6CB  VA 004402CB  75 e8                        jne      0x4402b5
FILE 0003F6CD  VA 004402CD  5f                           pop      edi
FILE 0003F6CE  VA 004402CE  be 90 fd 4a 00               mov      esi, 0x4afd90
FILE 0003F6D3  VA 004402D3  8d bc 24 c8 00 00 00         lea      edi, [esp + 0xc8]
FILE 0003F6DA  VA 004402DA  ba 98 fd 4a 00               mov      edx, 0x4afd98
FILE 0003F6DF  VA 004402DF  57                           push     edi
FILE 0003F6E0  VA 004402E0  2b c9                        sub      ecx, ecx
FILE 0003F6E2  VA 004402E2  49                           dec      ecx
FILE 0003F6E3  VA 004402E3  b0 00                        mov      al, 0
FILE 0003F6E5  VA 004402E5  f2 ae                        repne scasb al, byte ptr es:[edi]
FILE 0003F6E7  VA 004402E7  4f                           dec      edi
FILE 0003F6E8  VA 004402E8  8a 06                        mov      al, byte ptr [esi]
FILE 0003F6EA  VA 004402EA  88 07                        mov      byte ptr [edi], al
FILE 0003F6EC  VA 004402EC  3c 00                        cmp      al, 0
FILE 0003F6EE  VA 004402EE  74 10                        je       0x440300
FILE 0003F6F0  VA 004402F0  8a 46 01                     mov      al, byte ptr [esi + 1]
FILE 0003F6F3  VA 004402F3  83 c6 02                     add      esi, 2
FILE 0003F6F6  VA 004402F6  88 47 01                     mov      byte ptr [edi + 1], al
FILE 0003F6F9  VA 004402F9  83 c7 02                     add      edi, 2
FILE 0003F6FC  VA 004402FC  3c 00                        cmp      al, 0
FILE 0003F6FE  VA 004402FE  75 e8                        jne      0x4402e8
FILE 0003F700  VA 00440300  5f                           pop      edi
FILE 0003F701  VA 00440301  8d 84 24 c8 00 00 00         lea      eax, [esp + 0xc8]
FILE 0003F708  VA 00440308  e8 c1 1e 04 00               call     0x4821ce
FILE 0003F70D  VA 0044030D  89 84 24 2c 01 00 00         mov      dword ptr [esp + 0x12c], eax
FILE 0003F714  VA 00440314  85 c0                        test     eax, eax
FILE 0003F716  VA 00440316  74 31                        je       0x440349
FILE 0003F718  VA 00440318  bb 04 00 00 00               mov      ebx, 4
FILE 0003F71D  VA 0044031D  ba 01 00 00 00               mov      edx, 1
FILE 0003F722  VA 00440322  89 c1                        mov      ecx, eax
FILE 0003F724  VA 00440324  8d 84 24 2c 01 00 00         lea      eax, [esp + 0x12c]
FILE 0003F72B  VA 0044032B  e8 82 d2 04 00               call     0x48d5b2
FILE 0003F730  VA 00440330  8b 85 79 04 00 00            mov      eax, dword ptr [ebp + 0x479]
FILE 0003F736  VA 00440336  c7 40 3c 00 00 00 00         mov      dword ptr [eax + 0x3c], 0
FILE 0003F73D  VA 0044033D  8b 84 24 2c 01 00 00         mov      eax, dword ptr [esp + 0x12c]
FILE 0003F744  VA 00440344  e8 ec 1f 04 00               call     0x482335

; fopen-style runtime helper: VA 0x00482195 to 0x004821D8 (end exclusive)
FILE 00081595  VA 00482195  51                           push     ecx
FILE 00081596  VA 00482196  56                           push     esi
FILE 00081597  VA 00482197  57                           push     edi
FILE 00081598  VA 00482198  89 c6                        mov      esi, eax
FILE 0008159A  VA 0048219A  89 d9                        mov      ecx, ebx
FILE 0008159C  VA 0048219C  89 d0                        mov      eax, edx
FILE 0008159E  VA 0048219E  e8 5d fe ff ff               call     0x482000
FILE 000815A3  VA 004821A3  89 c3                        mov      ebx, eax
FILE 000815A5  VA 004821A5  85 c0                        test     eax, eax
FILE 000815A7  VA 004821A7  74 21                        je       0x4821ca
FILE 000815A9  VA 004821A9  31 c0                        xor      eax, eax
FILE 000815AB  VA 004821AB  e8 ad c9 01 00               call     0x49eb5d
FILE 000815B0  VA 004821B0  89 c7                        mov      edi, eax
FILE 000815B2  VA 004821B2  85 c0                        test     eax, eax
FILE 000815B4  VA 004821B4  74 12                        je       0x4821c8
FILE 000815B6  VA 004821B6  50                           push     eax
FILE 000815B7  VA 004821B7  8a 12                        mov      dl, byte ptr [edx]
FILE 000815B9  VA 004821B9  81 e2 ff 00 00 00            and      edx, 0xff
FILE 000815BF  VA 004821BF  89 f0                        mov      eax, esi
FILE 000815C1  VA 004821C1  e8 0b ff ff ff               call     0x4820d1
FILE 000815C6  VA 004821C6  89 c7                        mov      edi, eax
FILE 000815C8  VA 004821C8  89 f8                        mov      eax, edi
FILE 000815CA  VA 004821CA  5f                           pop      edi
FILE 000815CB  VA 004821CB  5e                           pop      esi
FILE 000815CC  VA 004821CC  59                           pop      ecx
FILE 000815CD  VA 004821CD  c3                           ret
FILE 000815CE  VA 004821CE  53                           push     ebx
FILE 000815CF  VA 004821CF  31 db                        xor      ebx, ebx
FILE 000815D1  VA 004821D1  e8 bf ff ff ff               call     0x482195
FILE 000815D6  VA 004821D6  5b                           pop      ebx
FILE 000815D7  VA 004821D7  c3                           ret

; mode parser: VA 0x00482000 to 0x004820D1 (end exclusive)
FILE 00081400  VA 00482000  53                           push     ebx
FILE 00081401  VA 00482001  51                           push     ecx
FILE 00081402  VA 00482002  52                           push     edx
FILE 00081403  VA 00482003  56                           push     esi
FILE 00081404  VA 00482004  83 ec 04                     sub      esp, 4
FILE 00081407  VA 00482007  89 c3                        mov      ebx, eax
FILE 00081409  VA 00482009  31 c0                        xor      eax, eax
FILE 0008140B  VA 0048200B  8a 03                        mov      al, byte ptr [ebx]
FILE 0008140D  VA 0048200D  31 d2                        xor      edx, edx
FILE 0008140F  VA 0048200F  e8 d6 41 01 00               call     0x4961ea
FILE 00081414  VA 00482014  88 04 24                     mov      byte ptr [esp], al
FILE 00081417  VA 00482017  25 ff 00 00 00               and      eax, 0xff
FILE 0008141C  VA 0048201C  83 f8 72                     cmp      eax, 0x72
FILE 0008141F  VA 0048201F  74 1b                        je       0x48203c
FILE 00081421  VA 00482021  83 f8 77                     cmp      eax, 0x77
FILE 00081424  VA 00482024  74 16                        je       0x48203c
FILE 00081426  VA 00482026  83 f8 61                     cmp      eax, 0x61
FILE 00081429  VA 00482029  74 11                        je       0x48203c
FILE 0008142B  VA 0048202B  b8 09 00 00 00               mov      eax, 9
FILE 00081430  VA 00482030  e8 1a c9 01 00               call     0x49e94f
FILE 00081435  VA 00482035  31 c0                        xor      eax, eax
FILE 00081437  VA 00482037  e9 8d 00 00 00               jmp      0x4820c9
FILE 0008143C  VA 0048203C  31 c9                        xor      ecx, ecx
FILE 0008143E  VA 0048203E  89 d6                        mov      esi, edx
FILE 00081440  VA 00482040  8a 4b 01                     mov      cl, byte ptr [ebx + 1]
FILE 00081443  VA 00482043  66 83 ce 03                  or       si, 3
FILE 00081447  VA 00482047  83 f9 2b                     cmp      ecx, 0x2b
FILE 0008144A  VA 0048204A  75 25                        jne      0x482071
FILE 0008144C  VA 0048204C  31 c0                        xor      eax, eax
FILE 0008144E  VA 0048204E  89 f2                        mov      edx, esi
FILE 00081450  VA 00482050  8a 43 02                     mov      al, byte ptr [ebx + 2]
FILE 00081453  VA 00482053  66 83 ce 40                  or       si, 0x40
FILE 00081457  VA 00482057  83 f8 62                     cmp      eax, 0x62
FILE 0008145A  VA 0048205A  74 11                        je       0x48206d
FILE 0008145C  VA 0048205C  83 f8 74                     cmp      eax, 0x74
FILE 0008145F  VA 0048205F  74 4a                        je       0x4820ab
FILE 00081461  VA 00482061  81 3d 0d 69 4c 00 00 02 00 00 cmp      dword ptr [0x4c690d], 0x200
FILE 0008146B  VA 0048206B  75 3e                        jne      0x4820ab
FILE 0008146D  VA 0048206D  89 f2                        mov      edx, esi
FILE 0008146F  VA 0048206F  eb 3a                        jmp      0x4820ab
FILE 00081471  VA 00482071  89 d0                        mov      eax, edx
FILE 00081473  VA 00482073  0c 40                        or       al, 0x40
FILE 00081475  VA 00482075  83 f9 62                     cmp      ecx, 0x62
FILE 00081478  VA 00482078  75 14                        jne      0x48208e
FILE 0008147A  VA 0048207A  89 c2                        mov      edx, eax
FILE 0008147C  VA 0048207C  8a 5b 02                     mov      bl, byte ptr [ebx + 2]
FILE 0008147F  VA 0048207F  81 e3 ff 00 00 00            and      ebx, 0xff
FILE 00081485  VA 00482085  83 fb 2b                     cmp      ebx, 0x2b
FILE 00081488  VA 00482088  75 21                        jne      0x4820ab
FILE 0008148A  VA 0048208A  0c 03                        or       al, 3
FILE 0008148C  VA 0048208C  eb 1b                        jmp      0x4820a9
FILE 0008148E  VA 0048208E  83 f9 74                     cmp      ecx, 0x74
FILE 00081491  VA 00482091  75 0a                        jne      0x48209d
FILE 00081493  VA 00482093  31 c0                        xor      eax, eax
FILE 00081495  VA 00482095  8a 43 02                     mov      al, byte ptr [ebx + 2]
FILE 00081498  VA 00482098  83 f8 2b                     cmp      eax, 0x2b
FILE 0008149B  VA 0048209B  eb ce                        jmp      0x48206b
FILE 0008149D  VA 0048209D  81 3d 0d 69 4c 00 00 02 00 00 cmp      dword ptr [0x4c690d], 0x200
FILE 000814A7  VA 004820A7  75 02                        jne      0x4820ab
FILE 000814A9  VA 004820A9  89 c2                        mov      edx, eax
FILE 000814AB  VA 004820AB  31 c0                        xor      eax, eax
FILE 000814AD  VA 004820AD  8a 04 24                     mov      al, byte ptr [esp]
FILE 000814B0  VA 004820B0  83 f8 77                     cmp      eax, 0x77
FILE 000814B3  VA 004820B3  75 05                        jne      0x4820ba
FILE 000814B5  VA 004820B5  80 ca 02                     or       dl, 2
FILE 000814B8  VA 004820B8  eb 0d                        jmp      0x4820c7
FILE 000814BA  VA 004820BA  83 f8 61                     cmp      eax, 0x61
FILE 000814BD  VA 004820BD  75 05                        jne      0x4820c4
FILE 000814BF  VA 004820BF  80 ca 82                     or       dl, 0x82
FILE 000814C2  VA 004820C2  eb 03                        jmp      0x4820c7
FILE 000814C4  VA 004820C4  80 ca 01                     or       dl, 1
FILE 000814C7  VA 004820C7  89 d0                        mov      eax, edx
FILE 000814C9  VA 004820C9  83 c4 04                     add      esp, 4
FILE 000814CC  VA 004820CC  5e                           pop      esi
FILE 000814CD  VA 004820CD  5a                           pop      edx
FILE 000814CE  VA 004820CE  59                           pop      ecx
FILE 000814CF  VA 004820CF  5b                           pop      ebx
FILE 000814D0  VA 004820D0  c3                           ret

; fwrite-style runtime helper: VA 0x0048D5B2 to 0x0048D794 (end exclusive)
FILE 0008C9B2  VA 0048D5B2  56                           push     esi
FILE 0008C9B3  VA 0048D5B3  57                           push     edi
FILE 0008C9B4  VA 0048D5B4  55                           push     ebp
FILE 0008C9B5  VA 0048D5B5  83 ec 0c                     sub      esp, 0xc
FILE 0008C9B8  VA 0048D5B8  50                           push     eax
FILE 0008C9B9  VA 0048D5B9  52                           push     edx
FILE 0008C9BA  VA 0048D5BA  89 cd                        mov      ebp, ecx
FILE 0008C9BC  VA 0048D5BC  8b 41 10                     mov      eax, dword ptr [ecx + 0x10]
FILE 0008C9BF  VA 0048D5BF  ff 15 dc 3d 4f 00            call     dword ptr [0x4f3ddc]
FILE 0008C9C5  VA 0048D5C5  f6 41 0c 02                  test     byte ptr [ecx + 0xc], 2
FILE 0008C9C9  VA 0048D5C9  75 1e                        jne      0x48d5e9
FILE 0008C9CB  VA 0048D5CB  b8 04 00 00 00               mov      eax, 4
FILE 0008C9D0  VA 0048D5D0  e8 7a 13 01 00               call     0x49e94f
FILE 0008C9D5  VA 0048D5D5  80 49 0c 20                  or       byte ptr [ecx + 0xc], 0x20
FILE 0008C9D9  VA 0048D5D9  8b 41 10                     mov      eax, dword ptr [ecx + 0x10]
FILE 0008C9DC  VA 0048D5DC  ff 15 e0 3d 4f 00            call     dword ptr [0x4f3de0]
FILE 0008C9E2  VA 0048D5E2  31 c0                        xor      eax, eax
FILE 0008C9E4  VA 0048D5E4  e9 a8 01 00 00               jmp      0x48d791
FILE 0008C9E9  VA 0048D5E9  0f af da                     imul     ebx, edx
FILE 0008C9EC  VA 0048D5EC  85 db                        test     ebx, ebx
FILE 0008C9EE  VA 0048D5EE  75 10                        jne      0x48d600
FILE 0008C9F0  VA 0048D5F0  8b 41 10                     mov      eax, dword ptr [ecx + 0x10]
FILE 0008C9F3  VA 0048D5F3  ff 15 e0 3d 4f 00            call     dword ptr [0x4f3de0]
FILE 0008C9F9  VA 0048D5F9  89 d8                        mov      eax, ebx
FILE 0008C9FB  VA 0048D5FB  e9 91 01 00 00               jmp      0x48d791
FILE 0008CA00  VA 0048D600  83 79 08 00                  cmp      dword ptr [ecx + 8], 0
FILE 0008CA04  VA 0048D604  75 07                        jne      0x48d60d
FILE 0008CA06  VA 0048D606  89 e8                        mov      eax, ebp
FILE 0008CA08  VA 0048D608  e8 07 1c 01 00               call     0x49f214
FILE 0008CA0D  VA 0048D60D  8b 45 0c                     mov      eax, dword ptr [ebp + 0xc]
FILE 0008CA10  VA 0048D610  8a 55 0c                     mov      dl, byte ptr [ebp + 0xc]
FILE 0008CA13  VA 0048D613  31 f6                        xor      esi, esi
FILE 0008CA15  VA 0048D615  83 e0 30                     and      eax, 0x30
FILE 0008CA18  VA 0048D618  80 e2 cf                     and      dl, 0xcf
FILE 0008CA1B  VA 0048D61B  89 74 24 0c                  mov      dword ptr [esp + 0xc], esi
FILE 0008CA1F  VA 0048D61F  89 44 24 08                  mov      dword ptr [esp + 8], eax
FILE 0008CA23  VA 0048D623  88 55 0c                     mov      byte ptr [ebp + 0xc], dl
FILE 0008CA26  VA 0048D626  f6 c2 40                     test     dl, 0x40
FILE 0008CA29  VA 0048D629  0f 84 db 00 00 00            je       0x48d70a
FILE 0008CA2F  VA 0048D62F  89 5c 24 10                  mov      dword ptr [esp + 0x10], ebx
FILE 0008CA33  VA 0048D633  83 7d 04 00                  cmp      dword ptr [ebp + 4], 0
FILE 0008CA37  VA 0048D637  75 44                        jne      0x48d67d
FILE 0008CA39  VA 0048D639  8b 44 24 10                  mov      eax, dword ptr [esp + 0x10]
FILE 0008CA3D  VA 0048D63D  3b 45 14                     cmp      eax, dword ptr [ebp + 0x14]
FILE 0008CA40  VA 0048D640  72 3b                        jb       0x48d67d
FILE 0008CA42  VA 0048D642  89 c3                        mov      ebx, eax
FILE 0008CA44  VA 0048D644  30 c3                        xor      bl, al
FILE 0008CA46  VA 0048D646  80 e7 fe                     and      bh, 0xfe
FILE 0008CA49  VA 0048D649  85 db                        test     ebx, ebx
FILE 0008CA4B  VA 0048D64B  75 02                        jne      0x48d64f
FILE 0008CA4D  VA 0048D64D  89 c3                        mov      ebx, eax
FILE 0008CA4F  VA 0048D64F  8b 54 24 04                  mov      edx, dword ptr [esp + 4]
FILE 0008CA53  VA 0048D653  8b 45 10                     mov      eax, dword ptr [ebp + 0x10]
FILE 0008CA56  VA 0048D656  e8 35 53 01 00               call     0x4a2990
FILE 0008CA5B  VA 0048D65B  89 c2                        mov      edx, eax
FILE 0008CA5D  VA 0048D65D  83 f8 ff                     cmp      eax, -1
FILE 0008CA60  VA 0048D660  74 15                        je       0x48d677
FILE 0008CA62  VA 0048D662  85 c0                        test     eax, eax
FILE 0008CA64  VA 0048D664  0f 85 74 00 00 00            jne      0x48d6de
FILE 0008CA6A  VA 0048D66A  ff 15 d8 3d 4f 00            call     dword ptr [0x4f3dd8]
FILE 0008CA70  VA 0048D670  c7 40 04 0c 00 00 00         mov      dword ptr [eax + 4], 0xc
FILE 0008CA77  VA 0048D677  80 4d 0c 20                  or       byte ptr [ebp + 0xc], 0x20
FILE 0008CA7B  VA 0048D67B  eb 61                        jmp      0x48d6de
FILE 0008CA7D  VA 0048D67D  8b 55 14                     mov      edx, dword ptr [ebp + 0x14]
FILE 0008CA80  VA 0048D680  8b 5d 04                     mov      ebx, dword ptr [ebp + 4]
FILE 0008CA83  VA 0048D683  8b 4c 24 10                  mov      ecx, dword ptr [esp + 0x10]
FILE 0008CA87  VA 0048D687  29 da                        sub      edx, ebx
FILE 0008CA89  VA 0048D689  39 ca                        cmp      edx, ecx
FILE 0008CA8B  VA 0048D68B  76 02                        jbe      0x48d68f
FILE 0008CA8D  VA 0048D68D  89 ca                        mov      edx, ecx
FILE 0008CA8F  VA 0048D68F  8b 74 24 04                  mov      esi, dword ptr [esp + 4]
FILE 0008CA93  VA 0048D693  89 d1                        mov      ecx, edx
FILE 0008CA95  VA 0048D695  8b 7d 00                     mov      edi, dword ptr [ebp]
FILE 0008CA98  VA 0048D698  06                           push     es
FILE 0008CA99  VA 0048D699  8c d8                        mov      eax, ds
FILE 0008CA9B  VA 0048D69B  8e c0                        mov      es, eax
FILE 0008CA9D  VA 0048D69D  57                           push     edi
FILE 0008CA9E  VA 0048D69E  89 c8                        mov      eax, ecx
FILE 0008CAA0  VA 0048D6A0  c1 e9 02                     shr      ecx, 2
FILE 0008CAA3  VA 0048D6A3  f2 a5                        movsd    dword ptr es:[edi], dword ptr [esi]
FILE 0008CAA5  VA 0048D6A5  8a c8                        mov      cl, al
FILE 0008CAA7  VA 0048D6A7  80 e1 03                     and      cl, 3
FILE 0008CAAA  VA 0048D6AA  f2 a4                        repne movsb byte ptr es:[edi], byte ptr [esi]
FILE 0008CAAC  VA 0048D6AC  5f                           pop      edi
FILE 0008CAAD  VA 0048D6AD  07                           pop      es
FILE 0008CAAE  VA 0048D6AE  8b 7d 04                     mov      edi, dword ptr [ebp + 4]
FILE 0008CAB1  VA 0048D6B1  01 d7                        add      edi, edx
FILE 0008CAB3  VA 0048D6B3  8a 7d 0d                     mov      bh, byte ptr [ebp + 0xd]
FILE 0008CAB6  VA 0048D6B6  89 7d 04                     mov      dword ptr [ebp + 4], edi
FILE 0008CAB9  VA 0048D6B9  80 cf 10                     or       bh, 0x10
FILE 0008CABC  VA 0048D6BC  8b 75 00                     mov      esi, dword ptr [ebp]
FILE 0008CABF  VA 0048D6BF  88 7d 0d                     mov      byte ptr [ebp + 0xd], bh
FILE 0008CAC2  VA 0048D6C2  01 d6                        add      esi, edx
FILE 0008CAC4  VA 0048D6C4  8b 45 04                     mov      eax, dword ptr [ebp + 4]
FILE 0008CAC7  VA 0048D6C7  8b 5d 14                     mov      ebx, dword ptr [ebp + 0x14]
FILE 0008CACA  VA 0048D6CA  89 75 00                     mov      dword ptr [ebp], esi
FILE 0008CACD  VA 0048D6CD  39 d8                        cmp      eax, ebx
FILE 0008CACF  VA 0048D6CF  74 06                        je       0x48d6d7
FILE 0008CAD1  VA 0048D6D1  f6 45 0d 04                  test     byte ptr [ebp + 0xd], 4
FILE 0008CAD5  VA 0048D6D5  74 07                        je       0x48d6de
FILE 0008CAD7  VA 0048D6D7  89 e8                        mov      eax, ebp
FILE 0008CAD9  VA 0048D6D9  e8 80 18 01 00               call     0x49ef5e
FILE 0008CADE  VA 0048D6DE  8b 4c 24 04                  mov      ecx, dword ptr [esp + 4]
FILE 0008CAE2  VA 0048D6E2  8b 74 24 0c                  mov      esi, dword ptr [esp + 0xc]
FILE 0008CAE6  VA 0048D6E6  8b 7c 24 10                  mov      edi, dword ptr [esp + 0x10]
FILE 0008CAEA  VA 0048D6EA  01 d1                        add      ecx, edx
FILE 0008CAEC  VA 0048D6EC  01 d6                        add      esi, edx
FILE 0008CAEE  VA 0048D6EE  89 4c 24 04                  mov      dword ptr [esp + 4], ecx
FILE 0008CAF2  VA 0048D6F2  89 74 24 0c                  mov      dword ptr [esp + 0xc], esi
FILE 0008CAF6  VA 0048D6F6  29 d7                        sub      edi, edx
FILE 0008CAF8  VA 0048D6F8  89 7c 24 10                  mov      dword ptr [esp + 0x10], edi
FILE 0008CAFC  VA 0048D6FC  74 67                        je       0x48d765
FILE 0008CAFE  VA 0048D6FE  f6 45 0c 20                  test     byte ptr [ebp + 0xc], 0x20
FILE 0008CB02  VA 0048D702  0f 84 2b ff ff ff            je       0x48d633
FILE 0008CB08  VA 0048D708  eb 5b                        jmp      0x48d765
FILE 0008CB0A  VA 0048D70A  8a 4d 0d                     mov      cl, byte ptr [ebp + 0xd]
FILE 0008CB0D  VA 0048D70D  31 ff                        xor      edi, edi
FILE 0008CB0F  VA 0048D70F  f6 c1 04                     test     cl, 4
FILE 0008CB12  VA 0048D712  74 11                        je       0x48d725
FILE 0008CB14  VA 0048D714  88 cd                        mov      ch, cl
FILE 0008CB16  VA 0048D716  80 e5 fa                     and      ch, 0xfa
FILE 0008CB19  VA 0048D719  88 e8                        mov      al, ch
FILE 0008CB1B  VA 0048D71B  0c 01                        or       al, 1
FILE 0008CB1D  VA 0048D71D  bf 01 00 00 00               mov      edi, 1
FILE 0008CB22  VA 0048D722  88 45 0d                     mov      byte ptr [ebp + 0xd], al
FILE 0008CB25  VA 0048D725  8b 54 24 04                  mov      edx, dword ptr [esp + 4]
FILE 0008CB29  VA 0048D729  31 c0                        xor      eax, eax
FILE 0008CB2B  VA 0048D72B  8a 02                        mov      al, byte ptr [edx]
FILE 0008CB2D  VA 0048D72D  42                           inc      edx
FILE 0008CB2E  VA 0048D72E  89 54 24 04                  mov      dword ptr [esp + 4], edx
FILE 0008CB32  VA 0048D732  89 ea                        mov      edx, ebp
FILE 0008CB34  VA 0048D734  e8 7c 51 ff ff               call     0x4828b5
FILE 0008CB39  VA 0048D739  f6 45 0c 30                  test     byte ptr [ebp + 0xc], 0x30
FILE 0008CB3D  VA 0048D73D  75 0d                        jne      0x48d74c
FILE 0008CB3F  VA 0048D73F  8b 4c 24 0c                  mov      ecx, dword ptr [esp + 0xc]
FILE 0008CB43  VA 0048D743  41                           inc      ecx
FILE 0008CB44  VA 0048D744  89 4c 24 0c                  mov      dword ptr [esp + 0xc], ecx
FILE 0008CB48  VA 0048D748  39 cb                        cmp      ebx, ecx
FILE 0008CB4A  VA 0048D74A  75 d9                        jne      0x48d725
FILE 0008CB4C  VA 0048D74C  85 ff                        test     edi, edi
FILE 0008CB4E  VA 0048D74E  74 15                        je       0x48d765
FILE 0008CB50  VA 0048D750  8a 75 0d                     mov      dh, byte ptr [ebp + 0xd]
FILE 0008CB53  VA 0048D753  80 e6 fa                     and      dh, 0xfa
FILE 0008CB56  VA 0048D756  88 f3                        mov      bl, dh
FILE 0008CB58  VA 0048D758  80 cb 04                     or       bl, 4
FILE 0008CB5B  VA 0048D75B  89 e8                        mov      eax, ebp
FILE 0008CB5D  VA 0048D75D  88 5d 0d                     mov      byte ptr [ebp + 0xd], bl
FILE 0008CB60  VA 0048D760  e8 f9 17 01 00               call     0x49ef5e
FILE 0008CB65  VA 0048D765  f6 45 0c 20                  test     byte ptr [ebp + 0xc], 0x20
FILE 0008CB69  VA 0048D769  74 06                        je       0x48d771
FILE 0008CB6B  VA 0048D76B  31 d2                        xor      edx, edx
FILE 0008CB6D  VA 0048D76D  89 54 24 0c                  mov      dword ptr [esp + 0xc], edx
FILE 0008CB71  VA 0048D771  8b 44 24 08                  mov      eax, dword ptr [esp + 8]
FILE 0008CB75  VA 0048D775  8b 0c 24                     mov      ecx, dword ptr [esp]
FILE 0008CB78  VA 0048D778  8b 5d 0c                     mov      ebx, dword ptr [ebp + 0xc]
FILE 0008CB7B  VA 0048D77B  31 d2                        xor      edx, edx
FILE 0008CB7D  VA 0048D77D  09 c3                        or       ebx, eax
FILE 0008CB7F  VA 0048D77F  8b 45 10                     mov      eax, dword ptr [ebp + 0x10]
FILE 0008CB82  VA 0048D782  89 5d 0c                     mov      dword ptr [ebp + 0xc], ebx
FILE 0008CB85  VA 0048D785  ff 15 e0 3d 4f 00            call     dword ptr [0x4f3de0]
FILE 0008CB8B  VA 0048D78B  8b 44 24 0c                  mov      eax, dword ptr [esp + 0xc]
FILE 0008CB8F  VA 0048D78F  f7 f1                        div      ecx
FILE 0008CB91  VA 0048D791  83 c4 14                     add      esp, 0x14

; CD drive-letter wrapper: VA 0x004673AC to 0x004673CD (end exclusive)
FILE 000667AC  VA 004673AC  52                           push     edx
FILE 000667AD  VA 004673AD  83 ec 0c                     sub      esp, 0xc
FILE 000667B0  VA 004673B0  04 41                        add      al, 0x41
FILE 000667B2  VA 004673B2  88 04 24                     mov      byte ptr [esp], al
FILE 000667B5  VA 004673B5  b4 3a                        mov      ah, 0x3a
FILE 000667B7  VA 004673B7  30 d2                        xor      dl, dl
FILE 000667B9  VA 004673B9  88 64 24 01                  mov      byte ptr [esp + 1], ah
FILE 000667BD  VA 004673BD  89 e0                        mov      eax, esp
FILE 000667BF  VA 004673BF  88 54 24 02                  mov      byte ptr [esp + 2], dl
FILE 000667C3  VA 004673C3  e8 58 ab 00 00               call     0x471f20
FILE 000667C8  VA 004673C8  83 c4 0c                     add      esp, 0xc
FILE 000667CB  VA 004673CB  5a                           pop      edx
FILE 000667CC  VA 004673CC  c3                           ret

; GetDriveTypeA wrapper: VA 0x00471F20 to 0x00471F38 (end exclusive)
FILE 00071320  VA 00471F20  51                           push     ecx
FILE 00071321  VA 00471F21  52                           push     edx
FILE 00071322  VA 00471F22  50                           push     eax
FILE 00071323  VA 00471F23  2e ff 15 30 13 53 00         call     dword ptr cs:[0x531330]
FILE 0007132A  VA 00471F2A  83 f8 05                     cmp      eax, 5
FILE 0007132D  VA 00471F2D  0f 94 c0                     sete     al
FILE 00071330  VA 00471F30  25 ff 00 00 00               and      eax, 0xff
FILE 00071335  VA 00471F35  5a                           pop      edx
FILE 00071336  VA 00471F36  59                           pop      ecx
FILE 00071337  VA 00471F37  c3                           ret

; DirectDraw hardware then emulation attempts: VA 0x0047CA75 to 0x0047CB41 (end exclusive)
FILE 0007BE75  VA 0047CA75  6a 00                        push     0
FILE 0007BE77  VA 0047CA77  53                           push     ebx
FILE 0007BE78  VA 0047CA78  6a 00                        push     0
FILE 0007BE7A  VA 0047CA7A  e8 e1 02 03 00               call     0x4acd60
FILE 0007BE7F  VA 0047CA7F  8b 2d 54 63 4c 00            mov      ebp, dword ptr [0x4c6354]
FILE 0007BE85  VA 0047CA85  89 c6                        mov      esi, eax
FILE 0007BE87  VA 0047CA87  85 ed                        test     ebp, ebp
FILE 0007BE89  VA 0047CA89  74 0e                        je       0x47ca99
FILE 0007BE8B  VA 0047CA8B  50                           push     eax
FILE 0007BE8C  VA 0047CA8C  68 a8 30 4b 00               push     0x4b30a8
FILE 0007BE91  VA 0047CA91  e8 5a fb 01 00               call     0x49c5f0
FILE 0007BE96  VA 0047CA96  83 c4 08                     add      esp, 8
FILE 0007BE99  VA 0047CA99  85 f6                        test     esi, esi
FILE 0007BE9B  VA 0047CA9B  0f 84 81 00 00 00            je       0x47cb22
FILE 0007BEA1  VA 0047CAA1  83 3d 54 63 4c 00 00         cmp      dword ptr [0x4c6354], 0
FILE 0007BEA8  VA 0047CAA8  74 0d                        je       0x47cab7
FILE 0007BEAA  VA 0047CAAA  68 c4 30 4b 00               push     0x4b30c4
FILE 0007BEAF  VA 0047CAAF  e8 3c fb 01 00               call     0x49c5f0
FILE 0007BEB4  VA 0047CAB4  83 c4 04                     add      esp, 4
FILE 0007BEB7  VA 0047CAB7  6a 00                        push     0
FILE 0007BEB9  VA 0047CAB9  53                           push     ebx
FILE 0007BEBA  VA 0047CABA  6a 02                        push     2
FILE 0007BEBC  VA 0047CABC  e8 9f 02 03 00               call     0x4acd60
FILE 0007BEC1  VA 0047CAC1  8b 15 54 63 4c 00            mov      edx, dword ptr [0x4c6354]
FILE 0007BEC7  VA 0047CAC7  89 c6                        mov      esi, eax
FILE 0007BEC9  VA 0047CAC9  85 d2                        test     edx, edx
FILE 0007BECB  VA 0047CACB  74 0e                        je       0x47cadb
FILE 0007BECD  VA 0047CACD  50                           push     eax
FILE 0007BECE  VA 0047CACE  68 dc 30 4b 00               push     0x4b30dc
FILE 0007BED3  VA 0047CAD3  e8 18 fb 01 00               call     0x49c5f0
FILE 0007BED8  VA 0047CAD8  83 c4 08                     add      esp, 8
FILE 0007BEDB  VA 0047CADB  85 f6                        test     esi, esi
FILE 0007BEDD  VA 0047CADD  74 43                        je       0x47cb22
FILE 0007BEDF  VA 0047CADF  83 3d 54 63 4c 00 00         cmp      dword ptr [0x4c6354], 0
FILE 0007BEE6  VA 0047CAE6  74 0d                        je       0x47caf5
FILE 0007BEE8  VA 0047CAE8  68 f8 30 4b 00               push     0x4b30f8
FILE 0007BEED  VA 0047CAED  e8 fe fa 01 00               call     0x49c5f0
FILE 0007BEF2  VA 0047CAF2  83 c4 04                     add      esp, 4
FILE 0007BEF5  VA 0047CAF5  56                           push     esi
FILE 0007BEF6  VA 0047CAF6  c7 03 00 00 00 00            mov      dword ptr [ebx], 0
FILE 0007BEFC  VA 0047CAFC  e8 13 2f 01 00               call     0x48fa14
FILE 0007BF01  VA 0047CB01  83 c4 04                     add      esp, 4
FILE 0007BF04  VA 0047CB04  6a 00                        push     0
FILE 0007BF06  VA 0047CB06  e8 b5 2e 01 00               call     0x48f9c0
FILE 0007BF0B  VA 0047CB0B  83 c4 04                     add      esp, 4
FILE 0007BF0E  VA 0047CB0E  50                           push     eax
FILE 0007BF0F  VA 0047CB0F  68 14 31 4b 00               push     0x4b3114
FILE 0007BF14  VA 0047CB14  e8 27 af ff ff               call     0x477a40
FILE 0007BF19  VA 0047CB19  83 c4 08                     add      esp, 8
FILE 0007BF1C  VA 0047CB1C  31 c0                        xor      eax, eax
FILE 0007BF1E  VA 0047CB1E  5d                           pop      ebp
FILE 0007BF1F  VA 0047CB1F  5e                           pop      esi
FILE 0007BF20  VA 0047CB20  5b                           pop      ebx
FILE 0007BF21  VA 0047CB21  c3                           ret
FILE 0007BF22  VA 0047CB22  83 3d 54 63 4c 00 00         cmp      dword ptr [0x4c6354], 0
FILE 0007BF29  VA 0047CB29  74 0d                        je       0x47cb38
FILE 0007BF2B  VA 0047CB2B  68 40 31 4b 00               push     0x4b3140
FILE 0007BF30  VA 0047CB30  e8 bb fa 01 00               call     0x49c5f0
FILE 0007BF35  VA 0047CB35  83 c4 04                     add      esp, 4
FILE 0007BF38  VA 0047CB38  b8 01 00 00 00               mov      eax, 1
FILE 0007BF3D  VA 0047CB3D  5d                           pop      ebp
FILE 0007BF3E  VA 0047CB3E  5e                           pop      esi
FILE 0007BF3F  VA 0047CB3F  5b                           pop      ebx
FILE 0007BF40  VA 0047CB40  c3                           ret

; IPX datagram socket arguments: VA 0x00481698 to 0x004816A6 (end exclusive)
FILE 00080A98  VA 00481698  68 e8 03 00 00               push     0x3e8
FILE 00080A9D  VA 0048169D  6a 02                        push     2
FILE 00080A9F  VA 0048169F  6a 06                        push     6
FILE 00080AA1  VA 004816A1  e8 90 b6 02 00               call     0x4acd36

; Additional IPX socket helper: VA 0x0049E390 to 0x0049E450 (end exclusive)
FILE 0009D790  VA 0049E390  53                           push     ebx
FILE 0009D791  VA 0049E391  51                           push     ecx
FILE 0009D792  VA 0049E392  52                           push     edx
FILE 0009D793  VA 0049E393  56                           push     esi
FILE 0009D794  VA 0049E394  57                           push     edi
FILE 0009D795  VA 0049E395  83 ec 08                     sub      esp, 8
FILE 0009D798  VA 0049E398  89 c6                        mov      esi, eax
FILE 0009D79A  VA 0049E39A  68 e8 03 00 00               push     0x3e8
FILE 0009D79F  VA 0049E39F  6a 02                        push     2
FILE 0009D7A1  VA 0049E3A1  6a 06                        push     6
FILE 0009D7A3  VA 0049E3A3  e8 8e e9 00 00               call     0x4acd36
FILE 0009D7A8  VA 0049E3A8  89 c3                        mov      ebx, eax
FILE 0009D7AA  VA 0049E3AA  89 c7                        mov      edi, eax
FILE 0009D7AC  VA 0049E3AC  83 f8 ff                     cmp      eax, -1
FILE 0009D7AF  VA 0049E3AF  0f 84 9b 00 00 00            je       0x49e450
FILE 0009D7B5  VA 0049E3B5  6a 04                        push     4
FILE 0009D7B7  VA 0049E3B7  8d 44 24 04                  lea      eax, [esp + 4]
FILE 0009D7BB  VA 0049E3BB  50                           push     eax
FILE 0009D7BC  VA 0049E3BC  6a 20                        push     0x20
FILE 0009D7BE  VA 0049E3BE  68 ff ff 00 00               push     0xffff
FILE 0009D7C3  VA 0049E3C3  ba 01 00 00 00               mov      edx, 1
FILE 0009D7C8  VA 0049E3C8  53                           push     ebx
FILE 0009D7C9  VA 0049E3C9  89 54 24 14                  mov      dword ptr [esp + 0x14], edx
FILE 0009D7CD  VA 0049E3CD  e8 5e e9 00 00               call     0x4acd30
FILE 0009D7D2  VA 0049E3D2  6a 04                        push     4
FILE 0009D7D4  VA 0049E3D4  8d 44 24 04                  lea      eax, [esp + 4]
FILE 0009D7D8  VA 0049E3D8  50                           push     eax
FILE 0009D7D9  VA 0049E3D9  68 0f 40 00 00               push     0x400f
FILE 0009D7DE  VA 0049E3DE  68 ff ff 00 00               push     0xffff
FILE 0009D7E3  VA 0049E3E3  53                           push     ebx
FILE 0009D7E4  VA 0049E3E4  e8 47 e9 00 00               call     0x4acd30
FILE 0009D7E9  VA 0049E3E9  6a 0e                        push     0xe
FILE 0009D7EB  VA 0049E3EB  56                           push     esi
FILE 0009D7EC  VA 0049E3EC  e8 e3 0d ff ff               call     0x48f1d4
FILE 0009D7F1  VA 0049E3F1  83 c4 08                     add      esp, 8
FILE 0009D7F4  VA 0049E3F4  68 52 04 00 00               push     0x452
FILE 0009D7F9  VA 0049E3F9  66 c7 06 06 00               mov      word ptr [esi], 6
FILE 0009D7FE  VA 0049E3FE  e8 21 e9 00 00               call     0x4acd24
FILE 0009D803  VA 0049E403  6a 0e                        push     0xe
FILE 0009D805  VA 0049E405  56                           push     esi
FILE 0009D806  VA 0049E406  53                           push     ebx
FILE 0009D807  VA 0049E407  66 89 46 0c                  mov      word ptr [esi + 0xc], ax
FILE 0009D80B  VA 0049E40B  e8 0e e9 00 00               call     0x4acd1e
FILE 0009D810  VA 0049E410  85 c0                        test     eax, eax
FILE 0009D812  VA 0049E412  75 27                        jne      0x49e43b
FILE 0009D814  VA 0049E414  8d 44 24 04                  lea      eax, [esp + 4]
FILE 0009D818  VA 0049E418  50                           push     eax
FILE 0009D819  VA 0049E419  56                           push     esi
FILE 0009D81A  VA 0049E41A  b9 0e 00 00 00               mov      ecx, 0xe
FILE 0009D81F  VA 0049E41F  53                           push     ebx
FILE 0009D820  VA 0049E420  89 4c 24 10                  mov      dword ptr [esp + 0x10], ecx
FILE 0009D824  VA 0049E424  e8 ef e8 00 00               call     0x4acd18
FILE 0009D829  VA 0049E429  85 c0                        test     eax, eax
FILE 0009D82B  VA 0049E42B  75 07                        jne      0x49e434
FILE 0009D82D  VA 0049E42D  83 7c 24 04 0e               cmp      dword ptr [esp + 4], 0xe
FILE 0009D832  VA 0049E432  74 2e                        je       0x49e462
FILE 0009D834  VA 0049E434  68 94 60 4b 00               push     0x4b6094
FILE 0009D839  VA 0049E439  eb 05                        jmp      0x49e440
FILE 0009D83B  VA 0049E43B  68 c0 60 4b 00               push     0x4b60c0
FILE 0009D840  VA 0049E440  e8 3b bc fe ff               call     0x48a080
FILE 0009D845  VA 0049E445  83 c4 04                     add      esp, 4
FILE 0009D848  VA 0049E448  57                           push     edi
FILE 0009D849  VA 0049E449  e8 c4 e8 00 00               call     0x4acd12
FILE 0009D84E  VA 0049E44E  eb 0d                        jmp      0x49e45d

; Runtime dynamic USER32 lookup: VA 0x004A6D32 to 0x004A6D5C (end exclusive)
FILE 000A6132  VA 004A6D32  68 8e 69 4b 00               push     0x4b698e
FILE 000A6137  VA 004A6D37  e8 fe 5e 00 00               call     0x4acc3a
FILE 000A613C  VA 004A6D3C  89 c3                        mov      ebx, eax
FILE 000A613E  VA 004A6D3E  85 c0                        test     eax, eax
FILE 000A6140  VA 004A6D40  0f 84 8a 00 00 00            je       0x4a6dd0
FILE 000A6146  VA 004A6D46  68 99 69 4b 00               push     0x4b6999
FILE 000A614B  VA 004A6D4B  50                           push     eax
FILE 000A614C  VA 004A6D4C  e8 e3 5e 00 00               call     0x4acc34
FILE 000A6151  VA 004A6D51  89 84 24 18 02 00 00         mov      dword ptr [esp + 0x218], eax
FILE 000A6158  VA 004A6D58  85 c0                        test     eax, eax
FILE 000A615A  VA 004A6D5A  74 72                        je       0x4a6dce

; Byte-writing software graphics routine: VA 0x0048C89A to 0x0048C908 (end exclusive)
FILE 0008BC9A  VA 0048C89A  53                           push     ebx
FILE 0008BC9B  VA 0048C89B  56                           push     esi
FILE 0008BC9C  VA 0048C89C  57                           push     edi
FILE 0008BC9D  VA 0048C89D  8b 74 24 14                  mov      esi, dword ptr [esp + 0x14]
FILE 0008BCA1  VA 0048C8A1  8b 7c 24 10                  mov      edi, dword ptr [esp + 0x10]
FILE 0008BCA5  VA 0048C8A5  8b 4c 24 18                  mov      ecx, dword ptr [esp + 0x18]
FILE 0008BCA9  VA 0048C8A9  03 35 64 79 4c 00            add      esi, dword ptr [0x4c7964]
FILE 0008BCAF  VA 0048C8AF  03 3d e0 78 4c 00            add      edi, dword ptr [0x4c78e0]
FILE 0008BCB5  VA 0048C8B5  8b 15 60 79 4c 00            mov      edx, dword ptr [0x4c7960]
FILE 0008BCBB  VA 0048C8BB  33 c0                        xor      eax, eax
FILE 0008BCBD  VA 0048C8BD  80 3d cc 78 4c 00 08         cmp      byte ptr [0x4c78cc], 8
FILE 0008BCC4  VA 0048C8C4  7f 61                        jg       0x48c927
FILE 0008BCC6  VA 0048C8C6  83 e9 04                     sub      ecx, 4
FILE 0008BCC9  VA 0048C8C9  78 3d                        js       0x48c908
FILE 0008BCCB  VA 0048C8CB  8b 1a                        mov      ebx, dword ptr [edx]
FILE 0008BCCD  VA 0048C8CD  8a 04 33                     mov      al, byte ptr [ebx + esi]
FILE 0008BCD0  VA 0048C8D0  8b 5a 04                     mov      ebx, dword ptr [edx + 4]
FILE 0008BCD3  VA 0048C8D3  3c ff                        cmp      al, 0xff
FILE 0008BCD5  VA 0048C8D5  74 02                        je       0x48c8d9
FILE 0008BCD7  VA 0048C8D7  88 07                        mov      byte ptr [edi], al
FILE 0008BCD9  VA 0048C8D9  8a 04 33                     mov      al, byte ptr [ebx + esi]
FILE 0008BCDC  VA 0048C8DC  8b 5a 08                     mov      ebx, dword ptr [edx + 8]
FILE 0008BCDF  VA 0048C8DF  3c ff                        cmp      al, 0xff
FILE 0008BCE1  VA 0048C8E1  74 03                        je       0x48c8e6
FILE 0008BCE3  VA 0048C8E3  88 47 01                     mov      byte ptr [edi + 1], al
FILE 0008BCE6  VA 0048C8E6  8a 04 33                     mov      al, byte ptr [ebx + esi]
FILE 0008BCE9  VA 0048C8E9  8b 5a 0c                     mov      ebx, dword ptr [edx + 0xc]
FILE 0008BCEC  VA 0048C8EC  3c ff                        cmp      al, 0xff
FILE 0008BCEE  VA 0048C8EE  74 03                        je       0x48c8f3
FILE 0008BCF0  VA 0048C8F0  88 47 02                     mov      byte ptr [edi + 2], al
FILE 0008BCF3  VA 0048C8F3  8a 04 33                     mov      al, byte ptr [ebx + esi]
FILE 0008BCF6  VA 0048C8F6  3c ff                        cmp      al, 0xff
FILE 0008BCF8  VA 0048C8F8  74 03                        je       0x48c8fd
FILE 0008BCFA  VA 0048C8FA  88 47 03                     mov      byte ptr [edi + 3], al
FILE 0008BCFD  VA 0048C8FD  83 e9 04                     sub      ecx, 4
FILE 0008BD00  VA 0048C900  8d 52 10                     lea      edx, [edx + 0x10]
FILE 0008BD03  VA 0048C903  8d 7f 04                     lea      edi, [edi + 4]
FILE 0008BD06  VA 0048C906  79 c3                        jns      0x48c8cb

; File-presence helper: VA 0x004886E0 to 0x00488723 (end exclusive)
FILE 00087AE0  VA 004886E0  53                           push     ebx
FILE 00087AE1  VA 004886E1  83 ec 0c                     sub      esp, 0xc
FILE 00087AE4  VA 004886E4  89 e0                        mov      eax, esp
FILE 00087AE6  VA 004886E6  50                           push     eax
FILE 00087AE7  VA 004886E7  8d 44 24 08                  lea      eax, [esp + 8]
FILE 00087AEB  VA 004886EB  50                           push     eax
FILE 00087AEC  VA 004886EC  8d 44 24 10                  lea      eax, [esp + 0x10]
FILE 00087AF0  VA 004886F0  50                           push     eax
FILE 00087AF1  VA 004886F1  8b 54 24 20                  mov      edx, dword ptr [esp + 0x20]
FILE 00087AF5  VA 004886F5  52                           push     edx
FILE 00087AF6  VA 004886F6  e8 2d fd ff ff               call     0x488428
FILE 00087AFB  VA 004886FB  83 c4 10                     add      esp, 0x10
FILE 00087AFE  VA 004886FE  8b 5c 24 08                  mov      ebx, dword ptr [esp + 8]
FILE 00087B02  VA 00488702  53                           push     ebx
FILE 00087B03  VA 00488703  e8 c0 fd ff ff               call     0x4884c8
FILE 00087B08  VA 00488708  83 c4 04                     add      esp, 4
FILE 00087B0B  VA 0048870B  83 7c 24 08 00               cmp      dword ptr [esp + 8], 0
FILE 00087B10  VA 00488710  74 08                        je       0x48871a
FILE 00087B12  VA 00488712  c7 44 24 08 01 00 00 00      mov      dword ptr [esp + 8], 1
FILE 00087B1A  VA 0048871A  8b 44 24 08                  mov      eax, dword ptr [esp + 8]
FILE 00087B1E  VA 0048871E  83 c4 0c                     add      esp, 0xc
FILE 00087B21  VA 00488721  5b                           pop      ebx
FILE 00087B22  VA 00488722  c3                           ret

; Generic file-open wrapper: VA 0x00488428 to 0x0048844B (end exclusive)
FILE 00087828  VA 00488428  53                           push     ebx
FILE 00087829  VA 00488429  56                           push     esi
FILE 0008782A  VA 0048842A  6a 00                        push     0
FILE 0008782C  VA 0048842C  8b 54 24 1c                  mov      edx, dword ptr [esp + 0x1c]
FILE 00087830  VA 00488430  52                           push     edx
FILE 00087831  VA 00488431  8b 5c 24 1c                  mov      ebx, dword ptr [esp + 0x1c]
FILE 00087835  VA 00488435  53                           push     ebx
FILE 00087836  VA 00488436  8b 4c 24 1c                  mov      ecx, dword ptr [esp + 0x1c]
FILE 0008783A  VA 0048843A  51                           push     ecx
FILE 0008783B  VA 0048843B  8b 74 24 1c                  mov      esi, dword ptr [esp + 0x1c]
FILE 0008783F  VA 0048843F  56                           push     esi
FILE 00087840  VA 00488440  e8 47 fe ff ff               call     0x48828c
FILE 00087845  VA 00488445  83 c4 14                     add      esp, 0x14
FILE 00087848  VA 00488448  5e                           pop      esi
FILE 00087849  VA 00488449  5b                           pop      ebx
FILE 0008784A  VA 0048844A  c3                           ret

; Termination callback: VA 0x00487B70 to 0x00487B77 (end exclusive)
FILE 00086F70  VA 00487B70  31 c0                        xor      eax, eax
FILE 00086F72  VA 00487B72  e9 28 38 01 00               jmp      0x49b39f

; Runtime exit cleanup: VA 0x0049B39F to 0x0049B3DC (end exclusive)
FILE 0009A79F  VA 0049B39F  52                           push     edx
FILE 0009A7A0  VA 0049B3A0  89 c2                        mov      edx, eax
FILE 0009A7A2  VA 0049B3A2  ff 15 88 39 4f 00            call     dword ptr [0x4f3988]
FILE 0009A7A8  VA 0049B3A8  ff 15 8c 39 4f 00            call     dword ptr [0x4f398c]
FILE 0009A7AE  VA 0049B3AE  89 d0                        mov      eax, edx
FILE 0009A7B0  VA 0049B3B0  e8 02 00 00 00               call     0x49b3b7
FILE 0009A7B5  VA 0049B3B5  5a                           pop      edx
FILE 0009A7B6  VA 0049B3B6  c3                           ret
FILE 0009A7B7  VA 0049B3B7  52                           push     edx
FILE 0009A7B8  VA 0049B3B8  89 c2                        mov      edx, eax
FILE 0009A7BA  VA 0049B3BA  ff 15 8c 39 4f 00            call     dword ptr [0x4f398c]
FILE 0009A7C0  VA 0049B3C0  ff 15 90 39 4f 00            call     dword ptr [0x4f3990]
FILE 0009A7C6  VA 0049B3C6  83 3d 60 3e 4f 00 00         cmp      dword ptr [0x4f3e60], 0
FILE 0009A7CD  VA 0049B3CD  74 06                        je       0x49b3d5
FILE 0009A7CF  VA 0049B3CF  ff 15 60 3e 4f 00            call     dword ptr [0x4f3e60]
FILE 0009A7D5  VA 0049B3D5  89 d0                        mov      eax, edx
FILE 0009A7D7  VA 0049B3D7  e9 59 3b 00 00               jmp      0x49ef35

; Runtime ExitProcess path: VA 0x0049EF35 to 0x0049EF54 (end exclusive)
FILE 0009E335  VA 0049EF35  89 c3                        mov      ebx, eax
FILE 0009E337  VA 0049EF37  e8 20 7f 00 00               call     0x4a6e5c
FILE 0009E33C  VA 0049EF3C  ba ff 00 00 00               mov      edx, 0xff
FILE 0009E341  VA 0049EF41  31 c0                        xor      eax, eax
FILE 0009E343  VA 0049EF43  e8 f3 83 00 00               call     0x4a733b
FILE 0009E348  VA 0049EF48  ff 15 14 3e 4f 00            call     dword ptr [0x4f3e14]
FILE 0009E34E  VA 0049EF4E  53                           push     ebx
FILE 0009E34F  VA 0049EF4F  e8 88 dd 00 00               call     0x4accdc
