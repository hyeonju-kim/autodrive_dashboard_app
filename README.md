# 🚗 자율주행 관제 대시보드

> 실시간 자율주행 차량 모니터링 및 관제를 위한 Flutter 기반 대시보드 애플리케이션

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![WebRTC](https://img.shields.io/badge/WebRTC-333333?style=for-the-badge&logo=webrtc&logoColor=white)](https://webrtc.org)
[![MQTT](https://img.shields.io/badge/MQTT-660066?style=for-the-badge&logo=mqtt&logoColor=white)](https://mqtt.org)

## 📘 프로젝트 개요

자율주행 관제 시스템 고도화를 위한 **내부 실험용 프로토타입**으로,  
연휴 기간(2025.10.07 ~ 2025.10.11) 동안 개인 주도로 개발된 프로젝트입니다.

기존 관제 웹의 한계를 개선하기 위해 **Flutter 기반 크로스 플랫폼 대시보드**를 구현하여,  
실시간 영상 + 텔레메트리 데이터를 하나의 앱에서 통합적으로 시각화하도록 설계하였습니다.

## 📋 목차

- [소개](#-소개)
- [주요 기능](#-주요-기능)
- [기술 스택](#-기술-스택)
- [시스템 구조](#-시스템-구조)
- [설치 및 실행](#-설치-및-실행)
- [화면 구성](#-화면-구성)
- [환경 설정](#-환경-설정)
- [데이터 프로토콜](#-데이터-프로토콜)
- [트러블슈팅](#-트러블슈팅)
- [라이선스](#-라이선스)

## 🎯 소개

자율주행 관제 대시보드는 자율주행 차량의 **실시간 상태 모니터링**, **영상 스트리밍**, **주행 데이터 시각화**를 제공하는 통합 관제 솔루션입니다.

### 핵심 가치

- 🎥 **실시간 영상 스트리밍**: Janus WebRTC를 통한 저지연 양방향 영상 전송
- 📊 **직관적인 데이터 시각화**: 속도, 배터리, 방향등, 운행 상태를 실시간 게이지로 표시
- ⚠️ **위험 운전 감지**: 급가속/급감속 실시간 알림
- 🚦 **차량 상태 모니터링**: 자율주행 모드, 브레이크, 작업 장비 상태 확인

## ✨ 주요 기능

### 📡 실시간 데이터 모니터링

- **속도 게이지**: 현재 속도를 km/h 단위로 실시간 표시
- **배터리 게이지**: 배터리 잔량을 퍼센트로 표시
- **방향 지시등**: 좌/우 방향등 및 비상등 상태 표시 (깜빡임 애니메이션)
- **급가속/급감속 알림**: 위험 운전 패턴 실시간 감지 및 경고

### 🎬 영상 스트리밍

- **듀얼 카메라 지원**: 2개의 스트림 동시 표시
- **WebRTC 기반**: 저지연 P2P 영상 전송
- **H.264 코덱**: 효율적인 영상 압축
- **자동 재연결**: 연결 끊김 시 자동 복구

### 🚙 차량 상태 표시

- **자율주행 모드**: DRIVE_AUTO 모드 감지 및 표시
- **브레이크 상태**: 브레이크 페달 작동 감지
- **작업 장비**: 브러쉬/블로워 등 작업 장비 상태
- **위험 운전**: 급가속(주황)/급감속(빨강) 실시간 경고

## 🛠 기술 스택

### Frontend
- **Flutter 3.x**: 크로스 플랫폼 UI 프레임워크
- **Dart 2.19+**: 프로그래밍 언어

### 통신
- **WebRTC**: 실시간 영상 스트리밍
    - `flutter_webrtc: ^0.9.12`
- **MQTT**: 차량 텔레메트리 데이터 전송
    - `mqtt_client: ^10.2.0`
    - WebSocket over MQTT

### 미디어 서버
- **Janus Gateway**: WebRTC 미디어 서버
    - Streaming Plugin 사용
    - TURN/STUN 서버 연동

### 데이터 흐름

1. **영상 스트림**: 차량 → Janus → Flutter App
2. **텔레메트리**: 차량 → EMQX → Flutter App
3. **제어 명령**: Flutter App → EMQX → 차량

## 🚀 설치 및 실행

### 필수 요구사항

- Flutter SDK 3.0 이상
- Dart 2.19 이상
- Android Studio / Xcode (모바일 개발 시)
- Chrome (웹 개발 시)