# Process Flow with Sequence Diagram
------------------------------------


┌─────────────────────────────────────────────────────────────────────────────┐
│                      NOTIFICATION PROCESS FLOW                              │
└─────────────────────────────────────────────────────────────────────────────┘

A. NOTIFICATION CREATION & SCHEDULING FLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Module  │───▶│  NTF    │───▶│ Target  │───▶│Template │───▶│Schedule │
│ Event   │    │ Request │    │Resolver │    │Renderer │    │  Job    │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     │ Create       │ Validate     │ Resolve      │ Render       │ Add to
     │ ntf_         │  request     │ recipients   │ content      │ scheduler
     │ notifications│              │              │              │
                    │              │              │              │
                    ▼              ▼              ▼              ▼
              ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
              │  Save   │    │ Save to │    │ Save to │    │ Create  │
              │Request  │    │ntf_     │    │ntf_     │    │schedule │
              │         │    │targets  │    │resolved │    │audit    │
              └─────────┘    └─────────┘    └─────────┘    └─────────┘

B. NOTIFICATION DISPATCH FLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│Schedule │───▶│Queue    │───▶│Provider │───▶│  Send   │───▶│  Log    │
│Trigger  │    │Manager  │    │Selector │    │         │    │Delivery │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     │ Fetch due    │ Add to       │ Select      │ Send via    │ Record
     │ notifica-    │ delivery     │ best        │ selected    │ status &
     │ tions        │ queue        │ provider    │ provider    │ response
                    │              │              │              │
                    ▼              ▼              ▼              ▼
              ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
              │Update   │    │Priority │    │Check    │    │Update   │
              │status   │    │queue    │    │fallback │    │metrics  │
              │         │    │ordering │    │if needed│    │         │
              └─────────┘    └─────────┘    └─────────┘    └─────────┘

C. ENGAGEMENT TRACKING FLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  User   │───▶│  Open   │───▶│ Click   │───▶│  Read   │───▶│ Update  │
│ Receives│    │ Tracking│    │Tracking │    │ Receipt │    │Analytics│
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     │ Display      │ Record       │ Record       │ Generate     │ Update
     │ notifica-    │ read_at      │ click_at     │ read         │ ntf_
     │ tion         │              │              │ receipt      │ delivery_
                    │              │              │ notification │ logs
                    ▼              ▼              ▼              ▼
              ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
              │Update   │    │Capture  │    │Mark     │    │Refresh  │
              │in-app   │    │IP &     │    │thread   │    │dashboard│
              │status   │    │useragent│    │as read  │    │metrics  │
              └─────────┘    └─────────┘    └─────────┘    └─────────┘

