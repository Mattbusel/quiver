# App Review notes

---

No account, login or network connection is required.

VERSION 1.1, IN-APP PURCHASE: Quiver is now free. One non-consumable in-app purchase, "Quiver Pro" (com.mattbusel.quiver.pro, $3.99, one time, no subscription), unlocks the true-size printable sight tape (PDF share), more than one bow setup, and the drop and drift chart. The arrow sheet, the bow and speed page and the fitted sight marks stay free. To see the paywall: on the Sight tape tab tap "Print the tape at true size", or tap the frosted drop chart on the Bow tab, or tap the setup name at the top right of any page and choose "New setup (Pro)". Buy and Restore purchase are on the paywall; Restore is also on the Quiver Pro card at the bottom of the Sight tape tab. People who bought the paid version get Pro automatically (checked with StoreKit AppTransaction in production only, so the sandbox always shows the paywall).

HOW TO USE: The Arrow tab holds the component weights; totals, FOC and energy update as you type. The Bow tab estimates or takes a measured speed and shows drop by distance. The Sight tape tab takes two or more sighted-in marks (distance and sight reading) and shows the fitted marks; with Pro, "Print or share the tape" opens a true-size preview with a Share PDF button (system share sheet, AirPrint or Files). The setup name at the top right of each page switches between bows.

PRIVACY: no data is collected. Settings are stored in a JSON file in the app's Documents folder on the device; the PDF is written to the same folder.

2. PURPOSE AND TARGET AUDIENCE
Quiver is a utility for target and hunting archers: an arrow build calculator (weight, FOC, kinetic energy, spine starting point) and a sight-tape generator. Adults; rated 4+. It does not sell, depict or promote weapons; it is a measurement tool for a sport.

3. SETUP AND ACCESS
No setup, login or credentials. Sensible defaults are present on first launch.

4. EXTERNAL SERVICES, TOOLS AND PLATFORMS
None. No analytics, advertising or third-party frameworks. Built with SwiftUI, StoreKit 2 (for the in-app purchase) and Foundation. The only network traffic is StoreKit talking to the App Store.

5. REGIONAL DIFFERENCES
None.

6. REGULATED INDUSTRY / PROTECTED MATERIAL
Not applicable. The formulas (AMO FOC, Epley-style estimates, ballistic integration) are standard and computed on the device. All art, text and code are my own work.
