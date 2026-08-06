# Triage Summary — T-1005: Teams Audio Dead on Three Machines in Same Meeting Room

**Logged:** 2026-08-04  
**Analyst:** DWP Service Desk

---

## Summary
Microsoft Teams audio is not functioning on three machines located in the same meeting room. No audio input or output is working during Teams calls.

---

## Impact
- **Who:** Three users in the same physical meeting room (identities to confirm)
- **How many affected:** 3 confirmed; whether the issue is room-specific or broader — to confirm
- **Business urgency:** HIGH — meeting room audio failure blocks collaboration and any scheduled calls or meetings using that room

---

## Known Facts
- Teams audio is non-functional on all three machines in the room
- All three affected machines are in the same meeting room — strongly suggests a shared environmental cause (shared audio device, room AV system, or recent change)
- Whether audio works in Teams on these machines outside the room — to confirm
- Whether the machines share a room audio system (e.g. a Poly, Jabra, or Logitech room device) or use individual headsets/speakers — to confirm

---

## Missing Information to Gather
1. Names, staff IDs, and device hostnames/asset tags for all three affected users
2. Audio device type in use — individual USB headsets, shared room speakerphone, integrated laptop speakers/microphone, or a dedicated Teams Rooms device
3. Whether the audio device appears in Windows Sound settings (Playback and Recording tabs) on each machine
4. Whether Teams shows the correct audio device selected under Settings > Devices
5. Whether audio works outside Teams (e.g. system sounds, browser audio) on the affected machines
6. Whether any Windows Updates, Teams updates, or audio driver updates were applied recently
7. Whether the room AV equipment (if present) has been powered off, unplugged, or recently changed
8. Whether Teams has been granted microphone permission in Windows Privacy settings (Settings > Privacy > Microphone)
9. Whether the issue is only in the meeting room or also occurs when the machines are used elsewhere (e.g. on a docking station or in another room)
10. Whether any Group Policy or Intune policy controls audio device access or Teams audio settings for these machines

---

## Likely Category
**Collaboration / Teams Audio — Shared room audio device failure or Teams device configuration issue**  
Sub-category: Shared audio hardware fault, driver issue, or device deselected in Teams  
*(All three machines in same room points strongly to a shared peripheral or room AV device as root cause rather than three independent machine faults)*

---

## Suggested First Diagnostic Step
Physically check the shared audio device (speakerphone, room hub, or AV system) — confirm it is powered on, correctly connected, and showing as active in Windows Sound settings on at least one of the affected machines. If a shared device is present, try disconnecting and reconnecting it (USB or Bluetooth). In Teams, go to Settings > Devices and confirm the correct microphone and speaker are selected — Teams sometimes defaults to "Windows Default" which may have changed. If audio works outside Teams but not within it, check Windows microphone privacy permissions for Teams specifically.
