
;  � � ������ = �  �  � = ������ � �
;  �                               �
;     ���������   ���  ����������          �  �����������������������������
;  � ����������� ����� ����   ���� �          Soundblaster Emulation     �
;  � ����������� ����� ����   ���� �      � �������������������������������
;  � ����������� ����� ����������  �       Section: VDD                  �
;  � ����   ���� ����� ���� ������ �     � Created: 21/01/02             �
;  � ����   ����  ���  ����   ���� �     � Last Modified: 21/01/02       �
;                   ���                  � Number Of Modifications: 000  �
;  �              ����             �     � INCs required: *none*         �
;       ������� ����                     � Written By: Martin Kiewitz    �
;  �     ڿڿ�����������           �     � (c) Copyright by              �
;  �     �ٳ������������           �     �      AiR ON-Line Software '02 �
;  �    �������    ����            �     � All rights reserved.
;  �              �������������    �    �������������������������������  �
;  �             ����ݳ �ڿ���     �
;  �            ����� �ĳ��ٳ�     �
;              ����������������     
;  �             ��                �
;  � Ĵ-=�i� ��-Li�� S��W���=-��� �


.386
.387
.model flat, SYSCALL
assume cs:FLAT, ds:FLAT, es:FLAT, ss:FLAT

Include SB_EQU.asm

_CODE                        Segment dword use32 Public 'CODE'
   callrange equ near
   Include SB_CODE.asm
   Include SB_MIXER.asm
_CODE                        EndS

; == Global data segment ==
_DATA                        Segment dword use32 Public 'DATA'
   Include SB_DATA.asm
_DATA           ENDS

; == Instance data segment ==
_IDATA                       Segment dword use32 Public 'DATA'
   Include SB_IDATA.asm
_IDATA                       EndS

End
