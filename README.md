# ft_services

**Minikube 위에 웹·DB·FTPS·모니터링 서비스를 각각 배포하고, MetalLB로 외부 접속을 구성한 42 Seoul 프로젝트입니다.** 2021년에 작성한 Kubernetes 실습으로, 서비스별 Docker 이미지 8개와 Deployment를 구성하고 배포 과정을 `setup.sh`로 연결합니다.

## 핵심 구현

| 주제 | 구현 내용 | 코드 |
|---|---|---|
| 서비스 분리 | Nginx, WordPress, phpMyAdmin, DB, FTPS와 모니터링 3종을 개별 Deployment로 배포 | [srcs](srcs) |
| 외부 접속 | MetalLB Layer 2와 공유 IP 설정, 서비스별 포트 분리 | [MetalLB](srcs/metallb/metallb.yaml), [Nginx Service](srcs/nginx/srcs/nginx.yaml) |
| 웹 요청 연결 | HTTP → HTTPS 전환, WordPress 리다이렉트, phpMyAdmin 프록시 | [Nginx 설정](srcs/nginx/srcs/default.conf) |
| 데이터 저장 | DB 2Gi·InfluxDB 1Gi PVC를 데이터 디렉토리에 연결 | [DB](srcs/mysql/srcs/mysql.yaml), [InfluxDB](srcs/influxdb/srcs/influxdb.yaml) |
| 메트릭 시각화 | Docker 메트릭 수집·저장과 서비스별 CPU·메모리 대시보드 8개 구성 | [Telegraf](srcs/telegraf/srcs/telegraf.yaml), [Grafana](srcs/grafana/srcs/grafana.yaml) |

## 저장소 구조

```text
.
├── setup.sh             # Minikube 생성·IP 치환·이미지 빌드·배포
└── srcs/
    ├── metallb/         # 외부 IP pool 설정
    ├── nginx/           # HTTPS 진입점·리다이렉트·프록시·SSH
    ├── wordpress/       # WordPress + Nginx + PHP-FPM
    ├── phpmyadmin/      # DB 관리 UI + Nginx + PHP-FPM
    ├── mysql/           # MariaDB 설정·초기 SQL·PVC
    ├── ftps/            # vsftpd·TLS·passive 포트
    ├── influxdb/        # 메트릭 저장·PVC
    ├── telegraf/        # Docker socket 기반 수집
    └── grafana/         # 데이터 소스·대시보드 provisioning
```

각 서비스 디렉토리는 `Dockerfile`과 `srcs/`의 설정·시작 스크립트·Kubernetes manifest로 구성됩니다. 상세 실행 조건은 [실행·확인 가이드](docs/operations.md)에 정리되어 있습니다.

## 서비스 연결

MetalLB는 `MINIKUBE_IP` 한 개를 주소 pool로 사용하도록 구성되어 있습니다. 외부용 Service에는 같은 공유 IP annotation을 지정하고 포트를 나누었습니다.

| 서비스 | 접근 방식 | 역할 |
|---|---|---|
| `nginx42` | LoadBalancer · 80 / 443 / 22 | HTTP 전환, HTTPS 웹 진입점, SSH |
| `wordpress42` | LoadBalancer · 5050 | WordPress HTTP 서비스 |
| `phpmyadmin42` | LoadBalancer · 5000 | phpMyAdmin HTTP 서비스 |
| `ftps42` | LoadBalancer · 20 / 21 / 20001–20002 | FTP 제어·데이터, passive FTPS |
| `grafana42` | LoadBalancer · 3000 | 모니터링 화면 |
| `mysql42` | ClusterIP · 3306 | WordPress·phpMyAdmin DB |
| `influxdb42` | ClusterIP · 8086 | 메트릭 저장·조회 |
| `telegraf42` | Docker socket 마운트 | 컨테이너 메트릭 수집 |

Nginx의 `/wordpress` 요청은 **HTTP 5050 포트로 307 리다이렉트**합니다. `/phpmyadmin/`은 HTTP 5000 포트로 프록시하며, 두 애플리케이션은 Service 이름 `mysql42`로 DB에 연결합니다.

## 모니터링과 상태 관리

Telegraf가 노드의 `/var/run/docker.sock`에서 컨테이너 메트릭을 10초 간격으로 수집하고, `influxdb42:8086`의 `telegraf42` DB로 전송합니다. Grafana는 ConfigMap으로 데이터 소스와 파일 기반 대시보드를 등록합니다.

[대시보드 JSON](srcs/grafana/dashboards)은 서비스별 `app` 태그로 CPU 누적 사용량과 메모리 사용량을 조회합니다. 실제 수집 태그와 패널 쿼리의 대응은 [메트릭 확인 절차](docs/operations.md#메트릭과-저장소-확인)에서 점검합니다.

모든 Deployment는 `replicas: 1`입니다. FTPS는 TCP 21, WordPress·phpMyAdmin은 HTTP 경로로 liveness probe를 구성합니다. DB와 InfluxDB의 데이터 경로는 PVC에 마운트합니다.

## 실행 진입점

**`setup.sh`는 시작 시 `minikube delete`와 `minikube delete --all`을 실행합니다. 기존 Minikube 클러스터와 데이터가 삭제되므로 전용 실습 환경에서만 실행합니다.**

스크립트는 macOS/BSD `sed -i ''`, VirtualBox driver, `~/goinfre`, Minikube 내부 Docker daemon을 전제로 합니다. [환경·버전 확인](docs/operations.md#실행-환경과-버전)을 마친 뒤 저장소 루트에서 실행합니다.

```bash
bash setup.sh
```

스크립트는 8개 이미지를 빌드하고 manifest를 적용한 뒤 Kubernetes Dashboard를 엽니다. 배포 상태와 외부 IP는 다음으로 확인합니다.

```bash
kubectl get deployments,pods,svc,pvc
minikube ip
```

## 사용 기술과 이력

| 기술 | 저장소 기준 |
|---|---|
| Kubernetes · Minikube · Docker | 로컬 이미지 빌드, `imagePullPolicy: Never`, Deployment·Service·ConfigMap·Secret·PVC |
| Alpine Linux | 모든 이미지 `3.12.0` |
| MetalLB | `0.9.5`, ConfigMap 기반 Layer 2 pool |
| 웹·파일 서비스 | Nginx, PHP 7, WordPress, phpMyAdmin `5.1.0`, vsftpd, OpenSSH |
| DB·모니터링 | MariaDB, Telegraf, InfluxDB, Grafana |

Alpine 3.12는 지원이 종료되었으며, MetalLB의 현재 구성 방식은 CRD 기반입니다. Grafana·Telegraf 패키지와 WordPress 다운로드는 버전이 고정되어 있지 않습니다. 재현에 영향을 주는 차이는 [버전·호환성 안내](docs/operations.md#실행-환경과-버전)에 정리했습니다.

[2021년 구현 커밋](https://github.com/tjung03/ft_services/commit/d4059563b9a54032b040b0a0972a29bb125b5111)에 이미지·배포 설정·대시보드가 함께 보관되어 있습니다.
