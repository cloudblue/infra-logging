default: test


STACK_VERSION := 7.14.0
RELEASE := helm-es-security
ELASTICSEARCH_IMAGE := docker.elastic.co/elasticsearch/elasticsearch:$(STACK_VERSION)
TIMEOUT := 1200s
ELASTIC_PASSWORD := opguZnVRKfqc3ilFcHjr

test: secrets install goss

purge-elastic:
	kubectl delete secrets elastic-credentials elastic-certificates elastic-certificate-pem elastic-certificate-crt --namespace=infrastructure || true
	# helm del $(RELEASE)

secrets-elastic:
	docker rm -f elastic-helm-charts-certs || true
	rm -f elastic-certificates.p12 elastic-certificate.pem elastic-certificate.crt elastic-stack-ca.p12 || true
	
	# password=$$([ ! -z "$$ELASTIC_PASSWORD" ] && echo $$ELASTIC_PASSWORD || echo $$(docker run --rm busybox:1.31.1 /bin/sh -c "< /dev/urandom tr -cd '[:alnum:]' | head -c20")) && \

	password=$(ELASTIC_PASSWORD) \
	docker run --name elastic-helm-charts-certs -i -w /tmp \
		$(ELASTICSEARCH_IMAGE) \
		/bin/sh -c " \
			elasticsearch-certutil ca --out /tmp/elastic-stack-ca.p12 --pass '' && \
			elasticsearch-certutil cert --name elasticsearch-master --dns elasticsearch-master --ca /tmp/elastic-stack-ca.p12 --pass '' --ca-pass '' --out /tmp/elastic-certificates.p12" && \
	docker cp elastic-helm-charts-certs:/tmp/elastic-certificates.p12 ./ && \
	docker rm -f elastic-helm-charts-certs && \
	openssl pkcs12 -nodes -passin pass:'' -in elastic-certificates.p12 -out elastic-certificate.pem && \
	openssl x509 -outform der -in elastic-certificate.pem -out elastic-certificate.crt && \
	kubectl create secret generic elastic-certificates --from-file=elastic-certificates.p12 --namespace=infrastructure && \
	kubectl create secret generic elastic-certificate-pem --from-file=elastic-certificate.pem --namespace=infrastructure && \
	kubectl create secret generic elastic-certificate-crt --from-file=elastic-certificate.crt --namespace=infrastructure && \
	kubectl create secret generic elastic-credentials --from-literal=password=$$password --from-literal=username=elastic --namespace=infrastructure  && \
	rm -f elastic-certificates.p12 elastic-certificate.pem elastic-certificate.crt elastic-stack-ca.p12

purge-kibana:
	kubectl delete secret kibana --namespace=infrastructure || true
	# helm del $(RELEASE)

secrets-kibana:
	encryptionkey=$$(docker run --rm busybox:1.31.1 /bin/sh -c "< /dev/urandom tr -dc _A-Za-z0-9 | head -c50") && \
	kubectl create secret generic kibana --from-literal=encryptionkey=$$encryptionkey --namespace=infrastructure