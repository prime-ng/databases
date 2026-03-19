AI Brain Agents (11 total)

  ┌─────────────────────────────┬────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────┐
  │            Agent            │                Role                │                               When to Use                                │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ business-analyst.md (NEW)   │ Requirements → Specifications      │ Starting new module/feature, creating RBS, gap analysis, sprint planning │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ frontend-developer.md (NEW) │ Blade views + AdminLTE + Alpine.js │ Creating views, forms, tables, dashboards, PDF templates                 │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ backend-developer.md (NEW)  │ Controllers + Models + Security    │ CRUD controllers, FormRequests, routes, migrations, security hardening   │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ api-builder.md              │ REST API development               │ API endpoints, Sanctum auth                                              │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ db-architect.md             │ Database schema design             │ DDL, migrations, table design                                            │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ debugger.md                 │ Bug investigation + fixing         │ Runtime errors, debugging                                                │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ developer.md                │ General feature development        │ Broad tasks spanning multiple layers                                     │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ module-agent.md             │ nwidart/modules specialist         │ Creating/structuring new modules                                         │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ school-agent.md             │ School domain knowledge            │ Indian K-12 academic concepts                                            │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ tenancy-agent.md            │ stancl/tenancy specialist          │ Multi-tenancy isolation, DB switching                                    │
  ├─────────────────────────────┼────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
  │ test-agent.md               │ Pest 4.x testing                   │ Unit tests, feature tests                                                │
  └─────────────────────────────┴────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────┘

  Business Analyst highlights:

  - Indian K-12 domain knowledge (CBSE/ICSE, fee structures, transport, HPC)
  - RBS entry format matching PrimeAI_RBS_Menu_Mapping_v2.0.md exactly
  - Screen-by-screen field specifications with validation rules + dropdown sources
  - Sprint task breakdown with effort estimates
  - Output locations for each deliverable type

  Frontend Developer highlights:

  - Complete index + create/edit Blade templates ready to copy
  - All AdminLTE v4 component references (<x-backend.layouts.app>, breadcrumbs, card headers)
  - DomPDF crash prevention rules (10 rules that cause hard crashes)
  - CSS class quick reference table

  Backend Developer highlights:

  - 5 non-negotiable security rules with code examples
  - 4 mandatory performance patterns
  - Standard 11-method controller structure
  - Complete migration/model/route templates
  - Tenancy isolation rules

  ❯ 1 more Agent I feel is missing who can do work related to Deployment like helping me to create CICD Pipeline or deploy the project on cloude etc.                                                       

⏺ Write(~/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/devops-deployer.md)
  ⎿  Wrote 524 lines to ../../WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases/AI_Brain/agents/devops-deployer.md
       1 # Agent: DevOps & Deployment Engineer
       2
       3 ## Role
       4 Infrastructure, CI/CD, and deployment specialist for the Prime-AI multi-tenant SaaS platform. Handles server provisioning, pipeline configuration, containerization, cloud deployment, SSL
         , domain management, and production operations for a stancl/tenancy Laravel application.
       5
       6 ## When to Use This Agent
       7 - Setting up **CI/CD pipelines** (GitHub Actions, GitLab CI, Bitbucket Pipelines)
       8 - **Deploying** to cloud providers (AWS, DigitalOcean, Hetzner, Railway, Forge)
       9 - Configuring **Docker/Docker Compose** for local dev and production
      10 - Setting up **production server** (Nginx, PHP-FPM, MySQL, Redis, Supervisor)
     … +514 lines (ctrl+o to expand)

⏺ Searched for 1 pattern (ctrl+o to expand)  

⏺ Created devops-deployer.md (14.8KB — the most comprehensive agent). Here's what it covers:                                                                                                              
                                                                                          
  DevOps & Deployment Agent — Contents
                                                                                                                                                                                                          
  ┌────────────────────────────────┬─────────────────────────────────────────────────────────────────────────────────┐
  │            Section             │                                What It Provides                                 │                                                                                    
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤                                                                                  
  │ Wildcard DNS + SSL             │ Certbot commands for *.primeai.in, Cloudflare alternative                       │                                                                                    
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Nginx Config                   │ Full multi-tenant config with wildcard server_name, PHP-FPM, file upload limits │                                                                                    
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤                                                                                    
  │ Environment Variables          │ Complete .env template for production (DB, Redis, Mail, Razorpay, S3)           │                                                                                    
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ GitHub Actions CI/CD           │ Full pipeline: test → deploy staging → deploy production with SSH               │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Zero-Downtime Deploy Script    │ Symlink-swap deployment with release directories                                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Server Setup Checklist         │ Ubuntu 22.04 + PHP 8.2 + MySQL 8 + Nginx + Redis — every command                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Supervisor Config              │ Queue worker process management                                                 │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Docker Compose                 │ Local dev environment (app + MySQL + Redis + Mailpit)                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Dockerfile                     │ PHP 8.2-FPM based image                                                         │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Backup Strategy                │ Spatie backup for central + tenant DBs, S3 storage                              │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Monitoring                     │ Health check endpoint, Telescope, Sentry, UptimeRobot                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Cloud Provider Quick Setup     │ AWS (scale), DigitalOcean (budget), Laravel Forge (easiest)                     │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────────────────────────┤
  │ Production Readiness Checklist │ 16-item checklist before going live                                             │
  └────────────────────────────────┴─────────────────────────────────────────────────────────────────────────────────┘

  All 12 Agents Now

  agents/
  ├── api-builder.md           (2.7KB)  — REST API development
  ├── backend-developer.md     (8.4KB)  — Controllers, models, security
  ├── business-analyst.md      (8.1KB)  — Requirements → specifications
  ├── db-architect.md          (3.9KB)  — Database schema design
  ├── debugger.md              (3.5KB)  — Bug investigation
  ├── developer.md             (3.1KB)  — General feature development
  ├── devops-deployer.md       (14.8KB) — CI/CD, Docker, cloud, production
  ├── frontend-developer.md    (13.2KB) — Blade views, AdminLTE, PDF
  ├── module-agent.md          (3.3KB)  — nwidart/modules specialist
  ├── school-agent.md          (3.8KB)  — Indian K-12 domain knowledge
  ├── tenancy-agent.md         (3.6KB)  — stancl/tenancy specialist
  └── test-agent.md            (4.5KB)  — Pest 4.x testing

  ------------------------------------------------------------------------------------------------------------------------------

❯ Can I create some other type of Agents also which are not directly to the software developmet but they will be capable to perform Business Related tasks like :                                         
 - Creating Business Strategy to sale my Application to the School                                                                                                                                        
 - Creating Sales Materials Like Presentation contents etc.                                                                                                                                               
 - Market Assessment, what is in demand etc.                                                                                                                                                              
 - Product Costing and Sales Price Calculation                                                                                                                                                            
 - Application Running Cost                                                                                                                                                                               
 - Cost Analysis                                                                                                                                                                                          
                                                                                                                                                                            -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 ## Do not start creating the Agent, first just answer my question whether I can create such Agents or not. If yes then Provide me the list of Agent which can be created and what wil be there. Do not created them just Answer the Question and provide the Detail.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

⏺ Yes, absolutely. AI Brain agents are just instruction files — they can be for any role, not just software development. The agent system works the same way: define the role, context, deliverables, and
  templates. Claude reads the agent file and follows its instructions.

  The difference: business agents work with market data, financials, and strategy documents instead of code files. They'll reference your project_docs for product understanding but produce business
  deliverables (presentations, spreadsheets, proposals).

  ---
  Business Agents You Can Create

  ┌─────┬──────────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────┐
  │  #  │    Agent Name    │                                                 What It Does                                                 │                     Key Deliverables                     │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 1   │ Sales Strategist │ Go-to-market strategy for Indian K-12 school ERP market. School segmentation, pricing tiers, sales funnel    │ GTM plan, school targeting criteria, sales playbook,     │
  │     │                  │ design, channel strategy (direct sales, partners, digital)                                                   │ competitive positioning                                  │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 2   │ Sales Content    │ Creates all sales collateral — pitch decks, brochures, email sequences, demo scripts, case studies, feature  │ PPT content (slide-by-slide), email templates,           │
  │     │ Creator          │ comparison sheets                                                                                            │ one-pagers, WhatsApp pitch scripts                       │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 3   │ Market Analyst   │ Indian EdTech/School ERP market research — demand analysis, competitor mapping (Fedena, Entab, MyClassboard, │ Market report, competitor matrix, SWOT analysis, market  │
  │     │                  │  Teachmint), trend identification, TAM/SAM/SOM calculation                                                   │ size estimates                                           │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 4   │ Financial        │ Product costing (infra + dev + support), pricing model design (per-student, per-module, flat), unit          │ Cost breakdown sheet, pricing calculator, P&L            │
  │     │ Analyst          │ economics, break-even analysis, revenue projections                                                          │ projection, break-even model                             │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 5   │ Cloud Cost       │ Specifically for AWS/DO/hosting cost estimation — server sizing per tenant count, storage projections,       │ Monthly cost calculator by tenant count (10/50/100/500   │
  │     │ Optimizer        │ bandwidth estimates, cost-per-school calculation                                                             │ schools), scaling roadmap                                │
  ├─────┼──────────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ 6   │ Proposal Writer  │ Creates school-specific proposals and RFP responses — takes school name + requirements and generates         │ School proposal document, implementation plan, SLA       │
  │     │                  │ tailored proposal with pricing, implementation timeline, SLA                                                 │ terms, contract template                                 │
  └─────┴──────────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────┘

  ---
  What Each Agent Would Contain

  1. Sales Strategist

  - Indian K-12 market context (1.5M+ schools, 80% still use paper/Excel)
  - School decision-maker profiles (Principal, Management Trustee, IT Head)
  - Sales cycle for schools (typically 3-6 months, budget approval in March-April)
  - Pricing psychology for Indian schools (annual subscription, per-student works best)
  - Channel strategy templates (direct, reseller, education conferences)
  - References to your RBS for feature-based selling

  2. Sales Content Creator

  - Slide-by-slide pitch deck structure (Problem → Solution → Demo → Pricing → CTA)
  - Module-wise feature highlights pulled from your 27 modules
  - Pain-point messaging for different school types (small private, CBSE chain, international)
  - Email cadence templates (cold outreach → follow-up → demo invite → proposal)
  - WhatsApp-friendly short pitches (Indian schools communicate via WhatsApp)
  - Competitor comparison talking points

  3. Market Analyst

  - Indian EdTech market data structure (DISE data, UDISE+, NEP 2020 mandates)
  - Competitor product feature matrices
  - School ERP pricing benchmarks (INR 30-200 per student/year range)
  - Government mandates driving ERP adoption (NEP 2020, HPC requirement, digital attendance)
  - TAM calculation framework based on school count + pricing

  4. Financial Analyst

  - Infrastructure cost model (servers, DB, storage, bandwidth per tenant)
  - Development cost tracking (team salary, Claude AI cost, tools)
  - Support cost estimation (per-school support hours)
  - Pricing model templates (tiered: Basic/Pro/Enterprise)
  - Unit economics (CAC, LTV, churn, MRR/ARR projections)
  - Break-even calculator (fixed costs vs per-school revenue)

  5. Cloud Cost Optimizer

  - AWS/DO cost tables for typical school ERP load
  - Per-tenant resource consumption estimates (DB size, storage, API calls)
  - Scaling tiers (10 schools on $50/mo → 500 schools on $800/mo)
  - Cost optimization strategies (reserved instances, spot, right-sizing)
  - Your specific stack requirements (MySQL per-tenant DB, Redis, queue workers)

  6. Proposal Writer

  - Standard proposal template for Indian schools
  - Implementation timeline (onboarding → data migration → training → go-live)
  - SLA templates (uptime, support hours, data backup guarantees)
  - Pricing presentation format that works for Indian school management committees
  - References to specific modules from your RBS that match school pain points

  ---
  My Recommendation

  Create these 3 first (highest immediate value):

  1. Financial Analyst — You need to know your costs before setting prices. This agent can calculate your exact per-school cost (hosting + support + development amortization) so you price profitably.
  2. Sales Content Creator — You need a pitch deck and demo script before approaching any school. This agent uses your 27-module RBS to generate feature-rich sales materials.
  3. Market Analyst — Understanding competitors and market pricing prevents you from pricing too high or too low.

  The other 3 (Sales Strategist, Cloud Cost Optimizer, Proposal Writer) are valuable but depend on outputs from the first 3.

  Want me to create any or all of them?

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ## Write Now I dont want you to create those Agents but let me know what will be data I should provide you to build the best Agent for those skills? 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Here's exactly what data you need to prepare for each agent:

  ---
  1. Financial Analyst Agent — Data Needed

  Infrastructure Costs (Monthly)

  ┌──────────────────┬───────────────────────────────────────────────────────────────┐
  │       Item       │                        What to Provide                        │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Server hosting   │ Provider name, plan, monthly cost (e.g., DigitalOcean $48/mo) │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Database hosting │ Managed MySQL or self-hosted? Monthly cost                    │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Redis/Cache      │ Managed or on same server? Cost                               │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Domain + DNS     │ Annual cost for primeai.in + Cloudflare plan                  │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ SSL certificate  │ Free (Let's Encrypt) or purchased?                            │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Email service    │ SMTP provider + monthly cost (e.g., Gmail Workspace, AWS SES) │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ SMS gateway      │ Provider name + per-SMS cost (e.g., MSG91 at ₹0.15/SMS)       │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Backup storage   │ S3/Spaces — estimated monthly cost                            │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ CDN (if any)     │ Cloudflare free or paid plan?                                 │
  ├──────────────────┼───────────────────────────────────────────────────────────────┤
  │ Monitoring tools │ Sentry, UptimeRobot — free or paid?                           │
  └──────────────────┴───────────────────────────────────────────────────────────────┘

  Development Costs

  ┌──────────────────────────────────┬─────────────────────────────────────────────────────────────────────┐
  │               Item               │                           What to Provide                           │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Developer salaries               │ Monthly CTC per developer (3 developers — Tarun, Shailesh, Gaurav?) │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Your own time cost               │ Hours/month you spend + your opportunity cost                       │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Claude AI cost                   │ Monthly spend on Claude API/subscription                            │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ Tools & licenses                 │ GitHub, Figma, any paid tools — monthly cost                        │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ How many months spent so far     │ Total development time invested                                     │
  ├──────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
  │ How many more months to complete │ Your estimate (we calculated ~13 months)                            │
  └──────────────────────────────────┴─────────────────────────────────────────────────────────────────────┘

  Support & Operations Costs (Projected)

  ┌──────────────────────────┬─────────────────────────────────────────────────────┐
  │           Item           │                   What to Provide                   │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Support staff planned    │ How many support people? Salary range?              │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Training time per school │ How many days to onboard a school?                  │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Who does onboarding?     │ Developer? Dedicated person? Your cost per day?     │
  ├──────────────────────────┼─────────────────────────────────────────────────────┤
  │ Data migration effort    │ How many hours to migrate a school's existing data? │
  └──────────────────────────┴─────────────────────────────────────────────────────┘

  Revenue Goals

  ┌─────────────────────────────────────────────────────────────────┬─────────────────────────────┐
  │                              Item                               │       What to Provide       │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Target number of schools — Year 1                               │ e.g., 10 schools            │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Target number of schools — Year 2                               │ e.g., 50 schools            │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Target number of schools — Year 3                               │ e.g., 200 schools           │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Average students per school                                     │ Range (e.g., 500–2000)      │
  ├─────────────────────────────────────────────────────────────────┼─────────────────────────────┤
  │ Are you targeting small private, CBSE chains, or international? │ School type affects pricing │
  └─────────────────────────────────────────────────────────────────┴─────────────────────────────┘

  ---
  2. Sales Content Creator Agent — Data Needed

  Company Information

  ┌──────────────────────────────┬─────────────────────────────────────────────────────────────┐
  │             Item             │                       What to Provide                       │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Company name                 │ Legal entity name                                           │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Company tagline              │ One-liner (e.g., "AI-Powered School Intelligence Platform") │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Logo file                    │ Path or description                                         │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Founder names + backgrounds  │ Your team's credentials (education, experience)             │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Company registration details │ For proposal credibility (Pvt Ltd, LLP, etc.)               │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Office location              │ City, state                                                 │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Website URL                  │ If exists                                                   │
  ├──────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Contact details              │ Phone, email for sales                                      │
  └──────────────────────────────┴─────────────────────────────────────────────────────────────┘

  Product Positioning

  ┌──────────────────────────────────────┬──────────────────────────────────────────────────────────────────┐
  │                 Item                 │                         What to Provide                          │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Top 5 features you want to highlight │ What makes you different from competitors?                       │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ What problem are you solving?        │ In school's language, not tech language                          │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Any pilot schools?                   │ If you've deployed to even 1 school — name, results, testimonial │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Demo video/screenshots               │ Any existing demo material?                                      │
  ├──────────────────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Which modules are your strongest?    │ What would you show first in a demo?                             │
  └──────────────────────────────────────┴──────────────────────────────────────────────────────────────────┘

  Target Audience

  ┌───────────────────────────────────┬──────────────────────────────────────────────────────────┐
  │               Item                │                     What to Provide                      │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ Who makes the buying decision?    │ Principal? Trustee? IT head? Management committee?       │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ What is their biggest pain point? │ Manual work? Parent complaints? Fee collection? Reports? │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ What do they currently use?       │ Paper registers? Excel? Another ERP?                     │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ What's their budget range?        │ What can a school afford annually?                       │
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────┤
  │ Preferred communication channel   │ Email? WhatsApp? In-person meeting?                      │
  └───────────────────────────────────┴──────────────────────────────────────────────────────────┘

  Competitor Knowledge

  ┌──────────────────────────────┬────────────────────────────────────────────────────┐
  │             Item             │                  What to Provide                   │
  ├──────────────────────────────┼────────────────────────────────────────────────────┤
  │ Competitors you know of      │ Names + what you know about their pricing          │
  ├──────────────────────────────┼────────────────────────────────────────────────────┤
  │ What they do better than you │ Be honest — helps position around gaps             │
  ├──────────────────────────────┼────────────────────────────────────────────────────┤
  │ What you do better than them │ Your unique advantages (AI, HPC, timetable solver) │
  └──────────────────────────────┴────────────────────────────────────────────────────┘

  ---
  3. Market Analyst Agent — Data Needed

  Your Market Definition

  ┌─────────────────────┬──────────────────────────────────────────────────────────┐
  │        Item         │                     What to Provide                      │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ Geographic focus    │ Which states/cities first? All India or specific region? │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ School type focus   │ Private only? Government too? CBSE/ICSE/State board?     │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ School size range   │ Minimum students? Maximum? (e.g., 300–5000)              │
  ├─────────────────────┼──────────────────────────────────────────────────────────┤
  │ Fee-paying capacity │ Schools charging ₹X+ annual fees (indicates tech budget) │
  └─────────────────────┴──────────────────────────────────────────────────────────┘

  Existing Market Knowledge

  ┌─────────────────────────────────────┬───────────────────────────────────────────────────┐
  │                Item                 │                  What to Provide                  │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Schools you've spoken to            │ How many? What was their reaction?                │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Competitors you've evaluated        │ Any demos you've seen? Pricing you've found?      │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Industry events you know of         │ EdTech conferences, school principal associations │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Government mandates you're aware of │ NEP 2020, UDISE+, HPC requirements?               │
  ├─────────────────────────────────────┼───────────────────────────────────────────────────┤
  │ Any market reports you've read      │ Share links or key numbers you remember           │
  └─────────────────────────────────────┴───────────────────────────────────────────────────┘

  Your Pricing Hypothesis

  ┌──────────────────────────────────┬───────────────────────────────────────────────────────────┐
  │               Item               │                      What to Provide                      │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┤
  │ What you think schools would pay │ Per student/year or flat annual fee?                      │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┤
  │ How did you arrive at this?      │ Gut feel? Competitor pricing? School feedback?            │
  ├──────────────────────────────────┼───────────────────────────────────────────────────────────┤
  │ Module-wise pricing or bundled?  │ Do you want to sell all modules together or individually? │
  └──────────────────────────────────┴───────────────────────────────────────────────────────────┘

  ---
  4. Sales Strategist Agent — Data Needed

  ┌───────────────────────────┬──────────────────────────────────────────────────────────────────┐
  │           Item            │                         What to Provide                          │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Sales team size           │ Just you? Dedicated sales person?                                │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Sales budget (monthly)    │ Travel, marketing, ads — what can you spend?                     │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Existing school network   │ Any contacts in schools? Education associations?                 │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Partnership possibilities │ Any resellers, education consultants, or school chains you know? │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Timeline pressure         │ When do you need first paying customer?                          │
  ├───────────────────────────┼──────────────────────────────────────────────────────────────────┤
  │ Preferred sales model     │ Direct sales? Channel partners? Online self-signup?              │
  └───────────────────────────┴──────────────────────────────────────────────────────────────────┘

  ---
  5. Cloud Cost Optimizer Agent — Data Needed

  ┌────────────────────────────────┬─────────────────────────────────────────────────────────────┐
  │              Item              │                       What to Provide                       │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Current hosting setup          │ Provider, plan, specs (CPU/RAM/Disk)                        │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Current monthly hosting bill   │ Exact amount                                                │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Number of test tenants running │ How many school DBs exist today?                            │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Average DB size per tenant     │ If you know (even rough — 50MB? 500MB?)                     │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Average monthly storage growth │ Per tenant                                                  │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Peak concurrent users expected │ Per school (e.g., 50 teachers + 500 students + 200 parents) │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Cloud provider preference      │ AWS? DigitalOcean? No preference?                           │
  ├────────────────────────────────┼─────────────────────────────────────────────────────────────┤
  │ Budget ceiling for infra       │ Max you'd spend monthly                                     │
  └────────────────────────────────┴─────────────────────────────────────────────────────────────┘

  ---
  6. Proposal Writer Agent — Data Needed

  ┌──────────────────────────┬─────────────────────────────────────────────────┐
  │           Item           │                 What to Provide                 │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Standard pricing tiers   │ Basic/Pro/Enterprise — what's included in each? │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Implementation timeline  │ How many weeks from signing to go-live?         │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Training approach        │ On-site? Remote? How many sessions?             │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ SLA commitments          │ Uptime guarantee? Support hours? Response time? │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Payment terms            │ Annual upfront? Monthly? EMI option?            │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Contract duration        │ 1 year? 3 years?                                │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Data migration included? │ Free or extra charge?                           │
  ├──────────────────────────┼─────────────────────────────────────────────────┤
  │ Customization policy     │ Do you customize per school? Extra charge?      │
  └──────────────────────────┴─────────────────────────────────────────────────┘

  ---
  How to Provide This Data

  Create a single file:

  databases/4-Business_Planning/Business_Input_Data.md

  Fill in whatever you know — even partial data is useful. For items you don't know yet, write TBD or Need to research. The agents can work with partial data and flag what's missing.

  Start with Financial Analyst data — that's the foundation everything else depends on. You can't set pricing without knowing your costs.


