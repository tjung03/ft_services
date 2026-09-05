# 실행과 확인

[저장소 소개](../README.md)

## 실행 환경과 버전

`setup.sh`는 **기존 Minikube 프로필 전체를 삭제한 뒤 새 환경을 구성**합니다. 전용 실습 장비에서 실행하며, 기존 클러스터를 사용하는 환경에서는 실행하지 않습니다.

| 항목 | 코드의 전제 | 현재 실행 시 확인 |
|---|---|---|
| 호스트 | VirtualBox, macOS/BSD `sed -i ''`, `~/goinfre` | VirtualBox 지원 환경·가상화와 쓰기 가능한 경로 필요. GNU sed 환경은 문법 조정 필요 |
| Minikube | 메모리 2048, 디스크 4096 설정, Kubernetes 버전 미지정 | 8개 워크로드와 PVC 3Gi가 함께 사용되므로 노드·스토리지 여유 확인 |
| 이미지·메트릭 | `docker-env`, `imagePullPolicy: Never`, Docker socket | Docker runtime 필요. 현재 Minikube의 기본 runtime은 containerd이며 Docker 선택은 `--container-runtime=docker` — [공식 안내](https://minikube.sigs.k8s.io/docs/handbook/pushing/) |
| Alpine | `3.12.0` | 3.12 지원은 2022-05-01 종료 — [지원 현황](https://alpinelinux.org/releases/) |
| Grafana·Telegraf | Alpine 3.12에 `latest-stable/community` 패키지 설치 | 서로 다른 Alpine 릴리스의 패키지를 섞으므로 현재 빌드 시 의존성·실행 파일 호환성 확인 |
| MetalLB | `0.9.5`와 ConfigMap | 0.13부터 Custom Resource 구성 사용. 현재 Layer 2 구성은 `IPAddressPool`·`L2Advertisement` — [호환성](https://metallb.io/), [구성](https://metallb.io/configuration/) |
| Nginx | `listen 443 ssl;`와 `ssl on;` | `ssl on;`은 Nginx 1.25.1에서 제거됨 — [공식 문서](https://nginx.org/en/docs/http/ngx_http_ssl_module.html) |
| WordPress·PHP | 시작 시 최신 WordPress 다운로드, `php7` 패키지 | 내려받은 WordPress와 실제 PHP 버전을 함께 확인 — [WordPress 요구사항](https://wordpress.org/about/requirements/) |
| InfluxDB | `outputs.influxdb`, DB 이름·InfluxQL 쿼리 | InfluxDB 1.x 방식의 구성. 설치된 패키지 버전과 설정 형식 확인 |

빌드·기동에 필요한 외부 파일은 실행 시 다운로드됩니다. `setup.sh`는 Minikube IP를 Nginx·DB dump·phpMyAdmin·FTPS·MetalLB 설정에 임시 치환하고 작업 후 되돌립니다. 중간에 중단되면 해당 파일에 치환값이 남았는지 확인합니다.

## 배포 확인

호환 환경에서 저장소를 내려받아 루트에서 실행합니다.

```bash
git clone https://github.com/tjung03/ft_services.git
cd ft_services
bash setup.sh
```

스크립트 실행 후 다른 터미널에서 확인합니다.

```bash
kubectl config current-context
kubectl get nodes
kubectl get deployments,pods,svc,pvc
kubectl get pods -n metallb-system
```

8개 Deployment의 가용 Pod, LoadBalancer Service의 외부 IP, `mysql-pv`·`influxdb-pv`의 `Bound` 상태를 확인합니다. PVC는 StorageClass를 지정하지 않으므로 기본 StorageClass의 동적 프로비저닝 또는 조건에 맞는 PV가 필요합니다.

웹 서비스는 시작 시 다운로드·DB 초기화가 진행됩니다. 준비가 늦거나 재시작을 반복하면 다음 로그와 이벤트를 확인합니다.

```bash
kubectl logs deployment/wordpress42
kubectl logs deployment/mysql42
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 접속 확인

```bash
FT_SERVICES_IP="$(minikube ip)"
curl -I "http://$FT_SERVICES_IP/"
curl -k -I "https://$FT_SERVICES_IP/wordpress"
curl -k -I "https://$FT_SERVICES_IP/phpmyadmin/"
curl -I "http://$FT_SERVICES_IP:5050/"
curl -I "http://$FT_SERVICES_IP:3000/login"
```

| 확인 대상 | 기대하는 구성 동작 |
|---|---|
| HTTP 80 | HTTPS로 301 전환 |
| HTTPS `/wordpress` | `http://IP:5050`으로 307 전환 |
| HTTPS `/phpmyadmin/` | Nginx가 phpMyAdmin 5000으로 전달 |
| HTTP 5050 | WordPress 페이지 또는 애플리케이션 응답 |
| HTTP 3000 | Grafana 로그인 화면 |
| FTPS | IP·21번 포트, explicit TLS와 passive mode로 연결. 데이터 포트 20001–20002 |

HTTPS와 FTPS는 시작 스크립트가 생성하는 자체 서명 인증서를 사용합니다. 위 `curl -k`는 로컬 확인을 위해 인증서 검증을 생략합니다.

DB·SSH·FTPS와 모니터링 설정에는 고정 실습 계정 값이 포함되어 있습니다. WordPress dump에도 사용자 데이터가 포함되어 있으므로 해당 값은 외부 환경에서 재사용하지 않고 격리된 실습망에서 사용합니다.

## 메트릭과 저장소 확인

Grafana의 데이터 소스는 `http://influxdb42:8086`, DB는 `telegraf42`입니다. 다음 순서로 수집과 조회를 확인합니다.

```bash
kubectl logs deployment/telegraf42
kubectl logs deployment/influxdb42
kubectl logs deployment/grafana42
kubectl exec deployment/influxdb42 -- influx -execute 'SHOW DATABASES'
kubectl exec deployment/influxdb42 -- influx -database telegraf42 -execute 'SHOW MEASUREMENTS'
kubectl exec deployment/influxdb42 -- influx -database telegraf42 -execute 'SHOW TAG KEYS FROM docker_container_cpu'
```

대시보드는 `docker_container_cpu.usage_total`과 `docker_container_mem.usage`를 `last()`로 조회합니다. CPU 패널은 누적 사용량을 표시합니다. 패널의 필터는 `app=서비스이름42`이므로 수집된 Docker label의 실제 태그 이름과 값이 맞는지 확인합니다.

InfluxDB 이미지는 `influxd`를 직접 실행합니다. Secret에 선언된 `INFLUXDB_DB`·사용자 환경 변수와 별개로, DB·사용자의 실제 생성 여부는 위 명령과 DB 조회로 확인합니다.

| 저장 경로 | 연결 | 재시작 시 확인 |
|---|---|---|
| MariaDB `/var/lib/mysql` | `mysql-pv` · 2Gi | 시작 스크립트가 매번 초기 SQL과 WordPress dump를 import하므로 기존 데이터·초기화 로그 확인 |
| InfluxDB `/var/lib/influxdb` | `influxdb-pv` · 1Gi | Pod 교체 후 같은 PVC와 기존 메트릭 조회 확인 |

WordPress dump의 헤더에는 MariaDB 10.4.19와 PHP 7.3.27이 기록되어 있습니다. 당시 SQL export 환경을 확인할 수 있는 자료입니다.

실습 종료 후에는 전용 Minikube 프로필을 삭제합니다. 이 명령은 해당 클러스터와 내부 데이터를 제거합니다.

```bash
minikube delete -p minikube
```
