---
title: WeDo DevOps
layout: single
parent: cool-stuff
description: A Robot Color Sorter demo.
thumbnail: assets/gigispizza-thumb.png
author: brett-terpstra
toc: true
date: 2021-01-01 12:00
categories: [oci,java]
tags: [nodejs,java]
---

### Robot Color Sorter

  * In this use case you will see how to use **Oracle Developer Cloud Service** related to **GIT, CI/CD pipelines** and integration (**webhooks integrations**) with external apps like **Jenkins, SonarQube or Slack**.
  * Robot Color Sorter demo show how to change code throught **snipplets** and how to use **kanban**, resolving issues or appliying patches to the code. Once the code is updated or changed, the **CI/CD pipeline** will complete the appropiate automated tasks to deploy the new **python** code into the robot.
  * After code deployment, last step will be manual and visual testing by the owner of the patch to verify the code and the functionality.

### Hybrid Apps (OKE & K8s raspberry cluster)

  * This use case is focused in the **Kubernetes (K8s) clusters**, on-prem and public cloud an how to deploy microservices that control phisical assets like robots or drones.
  * Our special and smart robot (**VECTOR**) will do a customized performance running from a **flow dashboard** (it's code is in Developer Cloud GIT repository).
  * Vector and drone controller are docker containers that we code in nodejs, contanerized in **docker** (prepared docker file) and deploy in the K8s cluster as part of **CI/CD pipeline**.

### [Gigi's Pizza - Microservices](https://wedocec-wedoinfra.cec.ocp.oraclecloud.com/site/wedodevops/use-cases/gigis-pizza.html)

  * Use case focused in **microservices and Multitenant DataBase**. We have **three microservices** coded in different laguages like python, nodejs and of course Java (**helidon framework**). This three microservices are part of a **delivery pizza app**, one microservice control the orders, other one control the pizza delivery and the last one control the accounting.
  1. Order data will be saved as **JSON** files in multitenant DB (java microservice)
  2. Delivery data will be saved as **graph node DB** (java microservice)
  3. Accounting data will be saved as regular **SQL data** (nodejs microservice)

### Data Base Transactions

  * **Distributed Transactions** are a pain on the neck and this use case demonstrate that DB had solve this problem. Why not do a mix between **microservices** and DB for transactions?. 
  * This use case show how two nodejs microservices can do transactions to **Oracle Data Base** **Cloud Service** without the distributed microservices transaction problem (no 2FC, no sagas pattern)

 

### Supporting Documentation

**More detail:** [https://wedocec-wedoinfra.cec.ocp.oraclecloud.com/site/wedodevops/index.html](https://wedocec-wedoinfra.cec.ocp.oraclecloud.com/site/wedodevops/index.html)

#### Demo Video

Different use cases:

Robot Color Sorter, Hybrid Apps, Gigi's Pizza and Transactions

#### Marketing video

Video describing the solution created by WEDO team from a Marketing point of view.

Do you want this demo?

Please send an email to Wedo Product Managers: carlos.casares@oracle.com and jesus.brasero@oracle.com or to WEDO DevOps Project Manager: ivan.sampedro@oracle.com

