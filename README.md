# Snowflake Iceberg Lakehouse on Azure

![Built with Kiro](https://img.shields.io/badge/Built_with-Kiro-8845f4?logo=robot&logoColor=white)&nbsp;![Terraform](https://img.shields.io/badge/Terraform-1.14+-623CE4?logo=terraform)&nbsp;![Azure](https://img.shields.io/badge/Azure-0078D4?logo=microsoftazure)&nbsp;![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?logo=snowflake)

A production-ready implementation of Apache Iceberg tables on Azure Blob Storage with Snowflake, fully automated with Terraform and GitHub Actions.

## Overview

This repository provides a complete data lakehouse solution featuring:

- **Apache Iceberg Tables**: Open table format for analytics on Azure Blob Storage
- **Snowflake Integration**: Query Iceberg tables using Snowflake's external catalog
- **Infrastructure as Code**: Terraform configurations for Azure and Snowflake resources
- **Automated Data Pipeline**: Snowpipe → Staging Table → Stream → Task → Iceberg Table
- **CI/CD Ready**: Two-phase GitHub Actions deployment with manual consent step

## Architecture

```mermaid
flowchart TB
    subgraph Azure["☁️ Azure Cloud"]
        subgraph RG["Resource Group"]
            SA["🗄️ Storage Account<br/>(ADLS Gen2)"]
            subgraph Container["📦 Blob Container: iceberg-data"]
                RAW["📁 iceberg/raw-data/csv/"]
                ICEBERG["📁 iceberg/sales/orders/<br/>(Iceberg metadata + data)"]
            end
            QUEUE["📬 Storage Queue<br/>(snowpipe-notifications)"]
            EG["⚡ Event Grid<br/>(BlobCreated events)"]
        end
    end

    subgraph Snowflake["❄️ Snowflake"]
        subgraph Security["🔐 Security"]
            SI["Storage Integration<br/>(Azure Blob Access)"]
            NI["Notification Integration<br/>(Queue Access)"]
            EV["External Volume<br/>(Iceberg Storage)"]
        end
        
        subgraph Pipeline["🔄 Data Pipeline"]
            STAGE["📥 External Stage<br/>(CSV files)"]
            PIPE["🚰 Snowpipe<br/>(Auto-ingest)"]
            STAGING["📋 Staging Table<br/>(DEMO_ORDERS_STAGING)"]
            STREAM["🌊 Stream<br/>(CDC capture)"]
            TASK["⏰ Task<br/>(1 min schedule)"]
        end
        
        subgraph Tables["📊 Tables"]
            ICE_TABLE["🧊 Iceberg Table<br/>(ORDERS_ICEBERG)"]
        end
    end

    subgraph AzureAD["🔑 Azure AD"]
        SP1["Service Principal<br/>(External Volume)"]
        SP2["Service Principal<br/>(Notification Int)"]
    end

    %% Data Flow
    RAW -->|"LIST files"| STAGE
    STAGE -->|"COPY INTO"| PIPE
    PIPE -->|"Load data"| STAGING
    STAGING -->|"CDC"| STREAM
    STREAM -->|"INSERT"| TASK
    TASK -->|"Write"| ICE_TABLE
    ICE_TABLE -->|"Store"| ICEBERG

    %% Event Flow
    RAW -.->|"BlobCreated"| EG
    EG -.->|"Notify"| QUEUE
    QUEUE -.->|"Trigger"| NI
    NI -.->|"Activate"| PIPE

    %% Auth Flow
    SI -->|"OAuth"| SP1
    NI -->|"OAuth"| SP2
    SP1 -->|"Blob Access"| SA
    SP2 -->|"Queue Access"| QUEUE
    EV -->|"OAuth"| SP1

    classDef azure fill:#0078D4,color:white
    classDef snowflake fill:#29B5E8,color:white
    classDef storage fill:#FF9900,color:white
    classDef security fill:#DD344C,color:white
    
    class SA,QUEUE,EG,RG azure
    class SI,NI,EV,STAGE,PIPE,STAGING,STREAM,TASK,ICE_TABLE snowflake
    class RAW,ICEBERG,Container storage
    class SP1,SP2,AzureAD security
```

## Data Flow

```mermaid
sequenceDiagram
    participant User as 👤 User/App
    participant Blob as 📦 Azure Blob
    participant EG as ⚡ Event Grid
    participant Queue as 📬 Storage Queue
    participant Pipe as 🚰 Snowpipe
    participant Stage as 📋 Staging Table
    participant Stream as 🌊 Stream
    participant Task as ⏰ Task
    participant Iceberg as 🧊 Iceberg Table

    User->>Blob: Upload CSV file
    Blob->>EG: BlobCreated event
    EG->>Queue: Route to queue
    Queue->>Pipe: Trigger notification
    Pipe->>Blob: Read from stage
    Pipe->>Stage: COPY INTO staging
    Stage->>Stream: CDC capture (append)
    
    loop Every 1 minute
        Task->>Stream: Check SYSTEM$STREAM_HAS_DATA
        alt Has Data
            Task->>Stream: SELECT from stream
            Task->>Iceberg: INSERT INTO iceberg
        end
    end
    
    User->>Iceberg: SELECT * FROM iceberg
    Iceberg-->>User: Query results
```

## Two-Phase Deployment

```mermaid
flowchart LR
    subgraph Phase1["📦 Phase 1: Base Infrastructure"]
        A1["Azure Resources<br/>• Resource Group<br/>• Storage Account<br/>• Container<br/>• Queue<br/>• Event Grid"]
        A2["Snowflake Resources<br/>• Warehouse<br/>• Database/Schema<br/>• External Volume<br/>• Storage Integration<br/>• Notification Integration<br/>• Stage, Table, Stream, Task, Pipe"]
    end

    subgraph Manual["🔐 Manual Consent (Required)"]
        M1["1️⃣ DESC EXTERNAL VOLUME<br/>→ Click AZURE_CONSENT_URL"]
        M2["2️⃣ DESC NOTIFICATION INTEGRATION<br/>→ Click AZURE_CONSENT_URL<br/>→ Copy client_id"]
    end

    subgraph Phase2["🔑 Phase 2: Role Assignments"]
        B1["External Volume SP<br/>• Storage Blob Data Contributor<br/>• Storage Blob Delegator"]
        B2["Notification Int SP<br/>• Storage Queue Data Contributor<br/>• Storage Queue Data Message Processor<br/>• Storage Queue Data Reader"]
    end

    Phase1 --> Manual
    Manual --> Phase2

    style Manual fill:#FFE4B5,stroke:#FF8C00
```

## Repository Structure

```
.
├── infra/
│   ├── platform/tf/           # Root orchestration module (entry point)
│   │   ├── main.tf            # Orchestrates Azure + Snowflake + Role Assignments
│   │   ├── locals.tf          # Configuration parsing from JSON
│   │   ├── variables.tf       # Input variables (incl. deployment_phase)
│   │   ├── outputs.tf         # Module outputs
│   │   ├── providers-azure.tf # Azure + AzureAD provider config
│   │   ├── providers-snowflake.tf
│   │   └── terraform.tfvars   # Variable values
│   ├── azure/tf/              # Azure child module
│   │   ├── main.tf            # Resource Group, Storage, Queue, Event Grid
│   │   └── modules/           # Nested modules (resource_group, storage_account, storage_container)
│   └── snowflake/tf/          # Snowflake child module
│       ├── main.tf            # Warehouses, databases, stages, pipes, streams, tasks
│       └── modules/           # Nested modules (external_volume, stream, task)
├── input-jsons/
│   ├── azure/config.json      # Azure resource configuration
│   └── snowflake/config.json  # Snowflake resource configuration
├── sample-data/               # Sample CSV files for testing
├── snowflake-ddl/             # Snowflake DDL Scripts (reference)
└── .github/workflows/         # GitHub Actions workflows
```

## Getting Started

### Prerequisites

- **Terraform** >= 1.14
- **Azure CLI** with active subscription
- **Snowflake Account** with ACCOUNTADMIN access
- **GitHub Repository** (for CI/CD)

### Quick Start (Local)

#### 1. Clone and Configure

```bash
git clone <repository-url>
cd <repository>

# Update configuration files
# - input-jsons/azure/config.json
# - input-jsons/snowflake/config.json
# - infra/platform/tf/terraform.tfvars
```

#### 2. Authenticate

```bash
# Azure
az login

# Snowflake (set private key)
export SNOWFLAKE_PRIVATE_KEY=$(cat path/to/snowflake_key.p8)
```

#### 3. Phase 1 Deployment

```bash
cd infra/platform/tf
terraform init
terraform apply -var="deployment_phase=1"
```

#### 4. Grant Azure Consent (Manual Step)

Run in Snowflake:

```sql
-- Get External Volume consent URL
DESC EXTERNAL VOLUME DEMO_AZURE_ICEBERG_VOLUME;
-- Open AZURE_CONSENT_URL in browser → Grant consent

-- Get Notification Integration consent URL  
DESC NOTIFICATION INTEGRATION DEMO_AZURE_SNOWPIPE_INT;
-- Open AZURE_CONSENT_URL in browser → Grant consent
-- Copy client_id from URL (e.g., ?client_id=XXXXXXXX)
```

#### 5. Phase 2 Deployment

```bash
# Update terraform.tfvars with client_id from step 4
# snowpipe_azure_client_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

terraform apply -var="deployment_phase=2"
```

#### 6. Create Iceberg Table

```sql
CREATE OR REPLACE ICEBERG TABLE DEMO_ICEBERG_DB.RAW_DATA.ORDERS_ICEBERG (
    order_id STRING,
    customer_id STRING,
    order_date DATE,
    product STRING,
    quantity INT,
    unit_price DECIMAL(10,2),
    region STRING
)
CATALOG = 'SNOWFLAKE'
EXTERNAL_VOLUME = 'DEMO_AZURE_ICEBERG_VOLUME'
BASE_LOCATION = 'iceberg/sales/orders/';
```

#### 7. Test Data Loading

```bash
# Upload sample data
az storage blob upload \
  --account-name <storage-account> \
  --container-name iceberg-data \
  --name iceberg/raw-data/csv/orders_2024_01.csv \
  --file sample-data/orders_2024_01.csv \
  --auth-mode login
```

```sql
-- Refresh pipe (if auto-ingest disabled)
ALTER PIPE DEMO_ICEBERG_DB.RAW_DATA.DEMO_ORDERS_PIPE REFRESH;

-- Check staging table
SELECT * FROM DEMO_ICEBERG_DB.RAW_DATA.DEMO_ORDERS_STAGING;

-- Resume task to move data to Iceberg
ALTER TASK DEMO_ICEBERG_DB.RAW_DATA.DEMO_ORDERS_TO_ICEBERG RESUME;

-- Query Iceberg table
SELECT * FROM DEMO_ICEBERG_DB.RAW_DATA.ORDERS_ICEBERG;
```

### GitHub Actions Deployment

The repository includes a two-phase GitHub Actions workflow:

#### Phase 1: Base Infrastructure
```bash
# Trigger manually with:
# - deployment_phase = 1
# - snowpipe_azure_client_id = (leave empty)
```

#### Manual Consent Step
Follow the console output instructions to grant Azure consent.

#### Phase 2: Role Assignments
```bash
# Trigger manually with:
# - deployment_phase = 2  
# - snowpipe_azure_client_id = <client-id-from-consent-url>
```

## Configuration

### Azure Configuration (`input-jsons/azure/config.json`)

```json
{
  "azure": {
    "resource_group": {
      "name": "snowflake-iceberg-rg",
      "location": "eastus"
    },
    "storage_account": {
      "base_name": "snwiceberg",
      "account_tier": "Standard",
      "replication_type": "LRS",
      "is_hns_enabled": true
    },
    "storage_container": {
      "name": "iceberg-data",
      "access_type": "private"
    },
    "table_root_prefixes": [
      "iceberg/sales/orders",
      "iceberg/raw-data/csv"
    ]
  }
}
```

### Snowflake Configuration (`input-jsons/snowflake/config.json`)

```json
{
  "warehouses": {
    "load_wh": {
      "name": "LOAD_WH",
      "warehouse_size": "X-SMALL",
      "auto_suspend": 60
    }
  },
  "external_volumes": {
    "azure_iceberg": {
      "name": "AZURE_ICEBERG_VOLUME",
      "storage_location_name": "azure-iceberg-location"
    }
  },
  "databases": {
    "iceberg_db": {
      "name": "ICEBERG_DB",
      "schemas": [
        { "name": "RAW_DATA" },
        { "name": "UTIL" }
      ]
    }
  }
}
```

### Terraform Variables (`terraform.tfvars`)

```hcl
# Project
project_code = "demo"
environment  = "devl"

# Azure
azure_subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
azure_tenant_id       = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Snowflake
snowflake_organization_name = "ORGNAME"
snowflake_account_name      = "ACCOUNTNAME"
snowflake_user              = "GH_ACTIONS_USER"
snowflake_role              = "ACCOUNTADMIN"

# Deployment phase (1 or 2)
deployment_phase = 1

# Snowpipe client_id (required for phase 2)
snowpipe_azure_client_id = ""
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `Service principal not found` | Grant consent via AZURE_CONSENT_URL first |
| `Pipe Notifications bind failure` | Ensure all queue roles are assigned to notification integration SP |
| `Stage shows no files` | Check file path matches stage URL (e.g., `iceberg/raw-data/csv/`) |
| `Stream has no data` | Enable change tracking on table, recreate stream with `SHOW_INITIAL_ROWS=TRUE` |
| `403 on Iceberg table creation` | Grant consent to external volume SP, assign blob roles |

### Debug Commands

```sql
-- Check pipe status
SELECT SYSTEM$PIPE_STATUS('DEMO_ICEBERG_DB.RAW_DATA.DEMO_ORDERS_PIPE');

-- Check copy history
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'DEMO_ICEBERG_DB.RAW_DATA.DEMO_ORDERS_STAGING',
  START_TIME => DATEADD(HOUR, -24, CURRENT_TIMESTAMP())
));

-- List files in stage
LIST @DEMO_ICEBERG_DB.UTIL.DEMO_AZURE_CSV_STAGE;

-- Check task history
SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
  TASK_NAME => 'DEMO_ORDERS_TO_ICEBERG'
));
```

## Resources Created

### Azure
- Resource Group
- Storage Account (ADLS Gen2 with HNS)
- Blob Container with Iceberg prefixes
- Storage Queue (for Snowpipe notifications)
- Event Grid System Topic + Subscription

### Snowflake
- Warehouse (LOAD_WH)
- Database + Schemas (ICEBERG_DB.RAW_DATA, ICEBERG_DB.UTIL)
- File Formats (CSV, JSON)
- Storage Integration (Azure Blob access)
- Notification Integration (Azure Queue access)
- External Volume (Iceberg storage)
- External Stage (CSV ingestion)
- Staging Table (ORDERS_STAGING)
- Stream (CDC on staging)
- Task (Stream to Iceberg)
- Snowpipe (auto-ingest)

### Azure Role Assignments
- External Volume SP: Storage Blob Data Contributor, Storage Blob Delegator
- Notification Integration SP: Storage Queue Data Contributor, Message Processor, Reader

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
