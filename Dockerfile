# ------ Stage 1 ----------

FROM maven:3.8.3-openjdk-17 as builder

WORKDIR /src

COPY . /src

RUN mvn clean install -DskipTests=true

#---------Stage2--------

FROM openjdk:17-alpine

COPY --from=builder /src/target/* /src/target/bankapp.jar

CMD [ "java","-jar","/src/target/* /src/target/bankapp.jar" ]

