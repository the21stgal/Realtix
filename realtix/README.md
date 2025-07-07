# Realtix 🏡  
_A Decentralized Real Estate Agent Network on the Blockchain_

Realtix is a Clarity smart contract that enables real estate agents to build professional profiles, track property sales, manage certifications, and exchange verified testimonials in a decentralized, permissionless environment. It promotes trust and collaboration among agents while ensuring transparency and ownership of professional data.

---

## ✨ Features

- **Agent Profiles**: Register professional details, specialization, and service areas.
- **Property Sales Records**: Record detailed, timestamped sales with visibility controls.
- **Certifications Management**: Add and verify industry certifications securely.
- **Client Testimonials**: Allow agents to leave endorsements for others, tracked and categorized.
- **Professional Referrals**: Request, accept, and validate agent-to-agent professional connections.
- **Visibility Controls**: Fine-grained access for public, licensed agents, or private views.
- **Admin Functions**: Owner-only actions for licensing agents, verifying credentials, and updating commission fees.

---

## 🧱 Smart Contract Structure

### Constants

- `VISIBILITY-PUBLIC (u0)`
- `VISIBILITY-LICENSED-AGENTS (u1)`
- `VISIBILITY-PRIVATE (u2)`

### Data Maps

- `agent-profiles`: Stores registered agent information.
- `property-sales`: Tracks individual sales per agent.
- `agent-certifications`: Lists credentials per agent.
- `client-testimonials`: Allows agents to endorse others.
- `agent-referrals`: Manages professional referral requests and status.
- `service-endorsements`: Counts category-based service endorsements.
- Additional maps for count tracking.

---

## 📚 Key Public Functions

| Function | Description |
|---------|-------------|
| `register-agent-profile` | Registers a new agent profile |
| `record-property-sale` | Records a property sale with optional listing date |
| `add-agent-certification` | Adds a new certification with visibility setting |
| `send-referral-request` | Sends a referral request to another agent |
| `accept-referral-request` | Accepts an incoming referral |
| `provide-service-testimonial` | Submits a testimonial and increments endorsements |
| `verify-agent-certification` | **Admin-only:** Verifies an agent's certification |
| `license-agent` | **Admin-only:** Marks an agent as licensed |
| `update-commission-fee` | **Admin-only:** Updates the global commission fee |

---

## 🔐 Access Control

- **Admin-only functions**: Require caller to be the `contract-owner` (the deploying address).
- **Testimonial visibility**: Only connected agents can endorse each other.
- **Data access**: `can-view-private-content` read-only function enforces privacy policies.

---

## 📖 Read-Only Queries

- `get-agent-profile`
- `get-property-sale`
- `get-agent-certification`
- `get-client-testimonial`
- `get-referral-status`
- `get-service-endorsement-count`
- `are-agents-connected`
- `can-view-private-content`

---

## 🛠 Deployment Notes

- Ensure you deploy the contract from the intended **admin address**, as it becomes the immutable `contract-owner`.
- Agents must **send and accept referrals** to form verified professional connections.
- Testimonials and certifications boost professional reputation on-chain.

## 👥 Contributors

- **Amobi Ndubuisi** – Creator & Architect  
- Contributions welcome! Fork the repo or suggest improvements.

---

## 💡 Future Ideas

- NFT-based certification badges
- Integration with on-chain property registries
- DAO-based agent guilds and governance
- Cross-contract licensing boards per region

