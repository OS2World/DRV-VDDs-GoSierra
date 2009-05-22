
// � � ������ = �  �  � = ������ � �
// �                               �
//    ���������   ���  ����������          �  �����������������������������
// � ����������� ����� ����   ���� �             MINSTALL Front-End      �
// � ����������� ����� ����   ���� �      � �������������������������������
// � ����������� ����� ����������  �       Section: MMOS/2 for eCS       �
// � ����   ���� ����� ���� ������ �     � Created: 28/10/02             �
// � ����   ����  ���  ����   ���� �     � Last Modified:                �
//                  ���                  � Number Of Modifications: 000  �
// �              ����             �     � INCs required: *none*         �
//      ������� ����                     � Written By: Martin Kiewitz    �
// �     ڿڿ�����������           �     � (c) Copyright by              �
// �     �ٳ������������           �     �      AiR ON-Line Software '02 �
// �    �������    ����            �     � All rights reserved.
// �              �������������    �    �������������������������������  �
// �             ����ݳ �ڿ���     �
// �            ����� �ĳ��ٳ�     �
//             ����������������     
// �             ��                �
// � Ĵ-=�i� ��-Li�� S��W���=-��� �

#define INCL_NOPMAPI
#define INCL_BASE
#define INCL_DOSSEMAPHORES
#include <os2.h>
#include <bsesub.h>
#include <malloc.h>

#define INCLUDE_STD_MAIN
#include <global.h>

HMTX     MINSTALL_FookUpSemamorph = NULLHANDLE;

ushort maincode (int argc, char *argv[]) {
   PSZ    ArgumentPtr     = argv[0];
   ULONG  ArgumentLen     = 0;
   ULONG  rc              = 0;
   ULONG  TempULONG       = 0;

   puts ("Multimedia Helper Daemon");

   if (DosCreateMutexSem("\\SEM32\\IBMMULTIMEDIAINSTALLXZYQ", &MINSTALL_FookUpSemamorph, 0, FALSE)) {
      puts ("...is already active!"); return 1;
    }

   while (1) {
      DosSleep (-1);
    }
   return 1;
 }
