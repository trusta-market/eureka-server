# syntax=docker/dockerfile:1.7

# ──────────────────────────────────────────────────────────────
# Builder — Gradle 로 bootJar 생성
# ──────────────────────────────────────────────────────────────
FROM gradle:8.10-jdk21-alpine AS builder
WORKDIR /workspace

# 캐시 활용 — build 설정 파일 먼저 복사해서 의존성 fetch
COPY settings.gradle build.gradle ./
COPY gradle ./gradle
RUN gradle dependencies --no-daemon || true

COPY src ./src

RUN gradle bootJar --no-daemon \
 && cp build/libs/*.jar /workspace/app.jar

# ──────────────────────────────────────────────────────────────
# Runtime — JRE 만 포함한 경량 이미지
# ──────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=builder /workspace/app.jar /app/app.jar

EXPOSE 8761

# MaxRAMPercentage — K8s container memory limit 의 75% 까지만 heap 사용 (overhead 여유)
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/app.jar"]
