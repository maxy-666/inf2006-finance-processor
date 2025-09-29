# INF2006 Project: Cloud-Native Financial Document Processor (AIaaS)

## 🎯 Project Overview
This project is an **AI-as-a-Service (AIaaS)** platform designed to automate and digitise financial functions. It will process uploaded documents (invoices, receipts) by using a multi-stage machine learning pipeline to perform OCR, layout analysis, entity extraction, validation, and auto-categorisation.

Our goal is to create a robust, scalable, and secure system that demonstrates competency in:
* **Cloud Architecture & IaC**: Fully automated, reproducible deployment on AWS.
* **Big Data Analytics**: Processing a large corpus of documents and leveraging structured/unstructured data.
* **AI-as-a-Service**: Integrating and orchestrating multiple advanced ML models for a practical business solution.

## ⚙️ Proposed Architecture (Mid-Term PoC)
The initial Proof-of-Concept (PoC) focuses on establishing the secure, serverless ingest pipeline:

1.  **Client/UI**: Uploads the document via a secure endpoint.
2.  **API Gateway**: Acts as the single entry point.
3.  **AWS Lambda**: Triggers the first stage of processing.
4.  **Amazon S3**: Stores the raw document securely.
5.  **AWS Textract**: Performs the initial Optical Character Recognition (OCR).

*(***Future Note:*** We will update this section with the Architecture Diagram once the PoC is deployed and link to the full Technical Report.)*

## 🛠️ Technology Stack
| Category | Technology | Purpose |
| :--- | :--- | :--- |
| **Cloud Provider** | AWS (Amazon Web Services) | Infrastructure hosting and managed services. |
| **IaC** | Terraform | Defining and deploying all AWS infrastructure (IaC). |
| **Orchestration** | AWS Lambda, SQS, Step Functions | Serverless computing and workflow management. |
| **Frontend** | [e.g., React, or plain HTML/JS] | User interface for document upload and result viewing. |
| **Key AI Service** | AWS Textract | Managed service for high-accuracy OCR. |

## 👥 Team & Contributions (Adjust to your names)
| Name | Role | Core Responsibility |
| :--- | :--- | :--- |
| **[Your Name]** | Cloud Architect & Front-End Developer | IaC (Terraform), API Gateway, Lambda integration, UI/UX. |
| **[Teammate 2]** | ML Developer | Model 2: Layout Analysis & Model Training Pipeline. |
| **[Teammate 3]** | ML Developer | Model 3/4: Entity Extraction & Categorisation Logic. |
| **[Teammate 4]** | ... | ... |
| **[Teammate 5]** | ... | ... |

---

## 2. Creating the `.gitignore` (Security and Cleanliness) 🛡️