"""Write fastlane/metadata/<locale>/ for the Oct 19 update: 13 store locales, full translated text.

    python Store/meta_oct19.py          writes the files and checks every length limit

No price words outside the description (Apple 2.3.7). Every claim matches the shipped build.
The app's screens are English, which every non-English description says.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "fastlane" / "metadata"
EULA = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
PRIVACY = "https://tensorust.com/apps/quiver/privacy/"
URL = "https://tensorust.com/apps/quiver/"

EN_DESC = """Quiver is an archer's field notebook: a range score book that reads your group, a sight tape fitted through the marks you actually shot, and the arrow build sheet, all on kraft paper.

THE RANGE
• Score WA 18 m, WA 70 m, WA 50 m compound, NFAA 300, Vegas 450, 3D courses or open practice
• Tap where each arrow lands on the face: Quiver scores it, Xs included, end by end
• It finds the centre of your group and tells you how far to move the sight, in millimetres
• Shot the round at a sight mark? One tap saves the corrected mark to your tape
• A new challenge every month, and a personal best for every round you shoot
• Share a kraft-paper scorecard poster of the round

ON YOUR LOCK SCREEN
• Sight Mark widget: your mark for any distance, walked in fives with plus and minus right on the Home Screen
• Lock Screen and StandBy widgets, and a Last Round widget with your trend
• A Live Activity keeps the end and the total on the Lock Screen and in the Dynamic Island while you score
• Ask Siri "What's my sight mark in Quiver?", or start a round from Control Center or the Action button

THE ARROW
• Shaft, point, insert, nock, vanes, wrap: total weight, balance point and FOC, drawn on the page
• Kinetic energy and momentum, checked against game-weight guidelines
• A spine starting point from draw weight, point weight and length

BOW AND SPEED
• Speed estimated from rated speed, draw and arrow weight, or your chronograph reading
• Drag from the arrow's diameter, weight and vanes
• Tuning notes for every setup

SIGHT TAPE
• Enter two or more marks and the tape is fitted through them with the modelled trajectory, so the far end is right, not just the middle
• Read the mark for any distance in a tap: the walk-back, the odd 3D target, the ranged buck
• mm, half-mm, inch and click scales, yards or metres, your label spacing and width
• Print it at true size as a PDF with a 10 mm check bar

QUIVER PRO, ONE PAYMENT
• Unlimited true-size tape prints
• A setup for every bow: hunting rig, 3D bow, the spare
• Drop and drift chart from 10 to 80 yards
• Score trends, and every arrow you've shot on one face
• The Sight Tape widget, and the score book as a spreadsheet
• Already bought Quiver before Pro existed? Pro is yours automatically.

QUIVER PLUS, SUBSCRIPTION
• Everything in Pro
• Insights: tiring late ends, consistency, group size over time, and how each distance is going
• iCloud backup of your setups, marks and every round
• Every notebook ink and its app icon while you're subscribed
• 5 scorecard poster credits every month
• A harder bonus challenge each month

Quiver Plus is $2.99 a month or $14.99 a year (prices vary by country), and the yearly plan starts with a 1 week free trial for new subscribers. Payment is charged to your Apple ID at confirmation of purchase, or when the free trial ends. The subscription renews automatically unless auto-renew is turned off at least 24 hours before the end of the current period, and renewal is charged within the 24 hours before the period ends. Manage or cancel any time in your Apple ID's subscription settings. Pro owners keep Pro whatever they choose.

EXTRAS
• Six notebook inks, each with its own app icon, 99 cents each
• One-off tape prints and scorecard poster packs

No account, no ads, no tracking. Your notebook stays on your iPhone; with Plus, a backup also goes to your own iCloud.

Terms of Use: """ + EULA + """
Privacy Policy: """ + PRIVACY

EN_NOTES = """The biggest Quiver update yet.

• Your sight mark on the Lock Screen, Home Screen and StandBy: walk the distance in fives right from the widget
• A Live Activity for the round you're scoring, in the Dynamic Island too
• Ask Siri for any sight mark, or start a round from Control Center
• A new challenge every month, and personal bests for every round
• Quiver Plus: Insights, iCloud backup, every ink and monthly posters, with a 1 week free trial on the yearly plan
• Two new inks: Carbon and Marsh
• Clearer VoiceOver labels and new haptics

Pro stays a one-time purchase, and everything you've entered carries over."""

EN_PROMO = "Your sight mark is now on the Lock Screen. Score a round with a Live Activity, take on a new challenge every month, and ask Siri for any mark, at any distance."

L = {}
L["en-US"] = dict(name="Quiver: Arrow & Sight Tape", subtitle="Archery score book & bow sight",
                  keywords="bowhunting,compound,recurve,spine,foc,3d,target,scorecard,nfaa,vegas,hunting,practice,group,range,deer,elk",
                  promo=EN_PROMO, desc=EN_DESC, notes=EN_NOTES)
# English storefronts outside the US: same copy, keywords aimed at how those archers search.
L["en-GB"] = dict(L["en-US"], subtitle="Archery score book & sight marks",
                  keywords="target,recurve,compound,barebow,longbow,club,indoor,outdoor,spine,foc,scoresheet,handicap,field,3d")
L["en-AU"] = dict(L["en-US"], keywords="bowhunting,target,recurve,compound,barebow,club,indoor,field,3d,spine,foc,scorecard,pig,deer,practice")
L["en-CA"] = dict(L["en-US"], keywords="bowhunting,compound,recurve,spine,foc,3d,target,scorecard,moose,deer,elk,hunting,practice,group,range")
for k in ("en-GB", "en-AU", "en-CA"):
    if len(L[k]["subtitle"]) > 30:
        L[k]["subtitle"] = "Archery scores & sight marks"

ES_DESC = """Quiver es la libreta de campo del arquero: una libreta de puntuación que lee tu agrupación, una cinta de mira ajustada a las marcas que de verdad tiraste y la ficha de tu flecha, todo en papel kraft.

EN EL CAMPO
• Puntúa WA 18 m, WA 70 m, WA 50 m compuesto, NFAA 300, Vegas 450, recorridos 3D o práctica libre
• Toca donde cayó cada flecha en la diana: Quiver la puntúa, X incluidas, tanda a tanda
• Encuentra el centro de tu agrupación y te dice cuántos milímetros mover la mira
• ¿Tiraste la ronda con una marca de mira? Un toque guarda la marca corregida en tu cinta
• Un reto nuevo cada mes y tu mejor marca personal en cada ronda
• Comparte un póster de la ronda en papel kraft

EN TU PANTALLA DE BLOQUEO
• Widget Marca de mira: tu marca para cualquier distancia, de cinco en cinco con más y menos desde la pantalla de inicio
• Widgets para la pantalla de bloqueo y StandBy, y un widget Última ronda con tu tendencia
• Una Actividad en vivo muestra la tanda y el total en la pantalla de bloqueo y en la Dynamic Island mientras puntúas
• Pide a Siri tu marca de mira o empieza una ronda desde el Centro de control o el botón de acción

LA FLECHA
• Tubo, punta, inserto, culatín, plumas y wrap: peso total, punto de equilibrio y FOC dibujados en la página
• Energía cinética y momento, comparados con las guías para cada tipo de caza
• Un punto de partida de spine según la potencia, el peso de la punta y la longitud

ARCO Y VELOCIDAD
• Velocidad estimada a partir de la velocidad nominal, la apertura y el peso de la flecha, o tu cronógrafo
• Resistencia del aire según diámetro, peso y plumas
• Notas de afinación para cada equipo

CINTA DE MIRA
• Con dos marcas o más, la cinta se ajusta a ellas con la trayectoria modelada, así que acierta también lejos
• Lee la marca de cualquier distancia con un toque
• Escalas en mm, medio mm, pulgadas o clics; yardas o metros
• Imprímela a tamaño real en PDF con una barra de control de 10 mm

QUIVER PRO, UN SOLO PAGO
• Impresiones de cinta ilimitadas, un equipo para cada arco, tabla de caída y deriva de 10 a 80 yardas
• Evolución de tus puntuaciones, todas tus flechas en una diana, el widget Cinta de mira y exportación a hoja de cálculo

QUIVER PLUS, SUSCRIPCIÓN
• Todo lo de Pro
• Análisis: tandas finales cansadas, regularidad, tamaño de agrupación y cómo vas en cada distancia
• Copia de seguridad en iCloud de equipos, marcas y rondas
• Todas las tintas y sus iconos mientras estés suscrito
• 5 pósters de puntuación cada mes y un reto extra más difícil cada mes

Quiver Plus cuesta 2,99 USD al mes o 14,99 USD al año (el precio varía según el país), y el plan anual empieza con 1 semana de prueba gratis para nuevos suscriptores. El pago se carga a tu Apple ID al confirmar la compra o al terminar la prueba. La suscripción se renueva automáticamente salvo que desactives la renovación al menos 24 horas antes de que termine el periodo actual; la renovación se cobra en las 24 horas previas. Gestiónala o cancélala cuando quieras en los ajustes de suscripciones de tu Apple ID. Quien tenga Pro lo conserva siempre.

EXTRAS
• Seis tintas para la libreta, cada una con su icono, 0,99 USD cada una
• Impresiones sueltas de cinta y packs de pósters

Sin cuenta, sin anuncios, sin rastreo. Las pantallas de la app están en inglés.

Términos de uso: """ + EULA + """
Política de privacidad: """ + PRIVACY

ES_NOTES = """La mayor actualización de Quiver.

• Tu marca de mira en la pantalla de bloqueo, la de inicio y StandBy
• Una Actividad en vivo para la ronda que estás puntuando, también en la Dynamic Island
• Pide a Siri cualquier marca o empieza una ronda desde el Centro de control
• Un reto nuevo cada mes y mejores marcas personales
• Quiver Plus: análisis, copia en iCloud, todas las tintas y pósters cada mes
• Dos tintas nuevas: Carbon y Marsh

Pro sigue siendo un solo pago y todo lo que has guardado se conserva."""

L["es-MX"] = dict(name="Quiver: tiro con arco", subtitle="Puntuación y marcas de mira",
                  keywords="arquería,flechas,diana,compuesto,recurvo,caza,cinta,spine,foc,3d,nfaa,vegas,blanco,práctica,agrupación",
                  promo="Tu marca de mira ahora está en la pantalla de bloqueo. Puntúa con una Actividad en vivo, acepta un reto nuevo cada mes y pide a Siri cualquier marca.",
                  desc=ES_DESC, notes=ES_NOTES)
L["es-ES"] = dict(L["es-MX"], keywords="arquería,flechas,diana,compuesto,recurvo,caza,cinta,spine,foc,3d,club,sala,campo,práctica,agrupación,arco")

DE_DESC = """Quiver ist das Feldnotizbuch für Bogenschützen: ein Schießbuch, das deine Gruppe liest, ein Visierband, das durch deine echten Visiermarken gelegt wird, und das Pfeil-Datenblatt, alles auf Kraftpapier.

AUF DEM PLATZ
• Werte WA 18 m, WA 70 m, WA 50 m Compound, NFAA 300, Vegas 450, 3D-Parcours oder freies Training
• Tippe, wo jeder Pfeil steckt: Quiver wertet ihn, X inklusive, Passe für Passe
• Quiver findet die Mitte deiner Gruppe und sagt dir, wie viele Millimeter das Visier wandern muss
• Mit einer Visiermarke geschossen? Ein Tipp speichert die korrigierte Marke auf deinem Band
• Jeden Monat eine neue Challenge und deine Bestleistung für jede Runde
• Teile ein Ergebnis-Poster der Runde auf Kraftpapier

AUF DEM SPERRBILDSCHIRM
• Widget Visiermarke: deine Marke für jede Distanz, in Fünferschritten mit Plus und Minus direkt auf dem Home-Bildschirm
• Widgets für Sperrbildschirm und StandBy, dazu ein Widget mit der letzten Runde und deinem Trend
• Eine Live-Aktivität zeigt Passe und Summe auf dem Sperrbildschirm und in der Dynamic Island, während du wertest
• Frag Siri nach deiner Visiermarke oder starte eine Runde aus dem Kontrollzentrum oder per Aktionstaste

DER PFEIL
• Schaft, Spitze, Insert, Nocke, Federn, Wrap: Gesamtgewicht, Schwerpunkt und FOC, auf die Seite gezeichnet
• Kinetische Energie und Impuls im Vergleich mit den Richtwerten für Wild
• Ein Spine-Startwert aus Zuggewicht, Spitzengewicht und Länge

BOGEN UND TEMPO
• Geschwindigkeit geschätzt aus IBO-Wert, Auszug und Pfeilgewicht, oder dein Chronograph
• Luftwiderstand aus Durchmesser, Gewicht und Federn
• Tuning-Notizen für jedes Setup

VISIERBAND
• Ab zwei Marken wird das Band mit der berechneten Flugbahn durch sie gelegt, damit auch die weiten Distanzen stimmen
• Lies die Marke für jede Distanz mit einem Tipp ab
• Skalen in mm, halben mm, Zoll oder Klicks; Yards oder Meter
• Drucke es in Originalgröße als PDF mit 10-mm-Kontrollbalken

QUIVER PRO, EINMALIG
• Unbegrenzte Banddrucke, ein Setup für jeden Bogen, Fall- und Drifttabelle von 10 bis 80 Yards
• Ergebnisverlauf, alle Pfeile auf einer Scheibe, das Widget Visierband und Export als Tabelle

QUIVER PLUS, ABO
• Alles aus Pro
• Analysen: schwächere späte Passen, Beständigkeit, Gruppengröße im Verlauf und wie jede Distanz läuft
• iCloud-Backup von Setups, Marken und allen Runden
• Alle Tinten und ihre App-Symbole, solange du abonniert hast
• 5 Ergebnis-Poster jeden Monat und eine schwerere Bonus-Challenge jeden Monat

Quiver Plus kostet 2,99 € im Monat oder 14,99 € im Jahr (Preise je nach Land), und der Jahresplan beginnt für neue Abonnenten mit 1 Woche gratis. Die Zahlung wird bei Kaufbestätigung oder am Ende des Probezeitraums über deine Apple-ID abgerechnet. Das Abo verlängert sich automatisch, sofern die automatische Verlängerung nicht mindestens 24 Stunden vor Ende des Zeitraums deaktiviert wird; die Verlängerung wird innerhalb der letzten 24 Stunden berechnet. Verwalten oder kündigen kannst du jederzeit in den Abo-Einstellungen deiner Apple-ID. Wer Pro besitzt, behält Pro in jedem Fall.

EXTRAS
• Sechs Notizbuch-Tinten mit eigenem App-Symbol, je 0,99 €
• Einzelne Banddrucke und Poster-Pakete

Kein Konto, keine Werbung, kein Tracking. Die Bildschirme der App sind auf Englisch.

Nutzungsbedingungen: """ + EULA + """
Datenschutz: """ + PRIVACY

L["de-DE"] = dict(name="Quiver: Bogensport & Visier", subtitle="Schießbuch und Visiermarken",
                  keywords="bogenschießen,pfeil,compound,recurve,blankbogen,langbogen,spine,foc,3d,scheibe,ergebnis,jagd,training,verein,halle",
                  promo="Deine Visiermarke jetzt auf dem Sperrbildschirm. Werte Runden mit Live-Aktivität, nimm jeden Monat eine neue Challenge an und frag Siri nach jeder Marke.",
                  desc=DE_DESC, notes="""Das größte Quiver-Update bisher.

• Deine Visiermarke auf Sperrbildschirm, Home-Bildschirm und in StandBy
• Eine Live-Aktivität für die laufende Runde, auch in der Dynamic Island
• Frag Siri nach jeder Marke oder starte eine Runde aus dem Kontrollzentrum
• Jeden Monat eine neue Challenge und Bestleistungen für jede Runde
• Quiver Plus: Analysen, iCloud-Backup, alle Tinten und monatliche Poster
• Zwei neue Tinten: Carbon und Marsh

Pro bleibt ein Einmalkauf, und alle deine Daten bleiben erhalten.""")

FR_DESC = """Quiver est le carnet de terrain de l'archer : une feuille de marque qui lit ton groupement, une bande de viseur ajustée sur les repères que tu as vraiment tirés, et la fiche de ta flèche, le tout sur papier kraft.

AU PAS DE TIR
• Marque WA 18 m, WA 70 m, WA 50 m poulies, NFAA 300, Vegas 450, parcours 3D ou entraînement libre
• Touche l'endroit où chaque flèche s'est plantée : Quiver la compte, X compris, volée après volée
• Il trouve le centre de ton groupement et te dit de combien de millimètres déplacer le viseur
• Tiré avec un repère ? Un toucher enregistre le repère corrigé sur ta bande
• Un nouveau défi chaque mois, et ton record personnel pour chaque épreuve
• Partage une affiche de ta feuille de marque sur papier kraft

SUR TON ÉCRAN VERROUILLÉ
• Widget Repère : ton repère pour n'importe quelle distance, de cinq en cinq avec plus et moins depuis l'écran d'accueil
• Widgets pour l'écran verrouillé et StandBy, et un widget Dernière épreuve avec ta tendance
• Une Activité en direct affiche la volée et le total sur l'écran verrouillé et dans la Dynamic Island pendant que tu marques
• Demande ton repère à Siri, ou lance une épreuve depuis le centre de contrôle ou le bouton Action

LA FLÈCHE
• Tube, pointe, insert, encoche, plumes, wrap : poids total, point d'équilibre et FOC, dessinés sur la page
• Énergie cinétique et quantité de mouvement, comparées aux repères pour le gibier
• Un spine de départ selon la puissance, le poids de pointe et la longueur

ARC ET VITESSE
• Vitesse estimée depuis la vitesse IBO, l'allonge et le poids de flèche, ou ton chronographe
• Traînée selon le diamètre, le poids et l'empennage
• Notes de réglage pour chaque équipement

BANDE DE VISEUR
• Dès deux repères, la bande passe par eux avec la trajectoire modélisée : juste aussi aux longues distances
• Lis le repère de n'importe quelle distance d'un toucher
• Échelles en mm, demi-mm, pouces ou clics ; yards ou mètres
• Imprime-la à taille réelle en PDF avec une barre de contrôle de 10 mm

QUIVER PRO, UN SEUL PAIEMENT
• Impressions illimitées, un équipement par arc, table de chute et de dérive de 10 à 80 yards
• Évolution des scores, toutes tes flèches sur un blason, le widget Bande et l'export en tableur

QUIVER PLUS, ABONNEMENT
• Tout Pro
• Analyses : fatigue en fin d'épreuve, régularité, taille du groupement dans le temps et chaque distance
• Sauvegarde iCloud de tes équipements, repères et épreuves
• Toutes les encres et leurs icônes tant que tu es abonné
• 5 affiches par mois et un défi bonus plus difficile chaque mois

Quiver Plus coûte 2,99 € par mois ou 14,99 € par an (prix variables selon le pays), et l'offre annuelle commence par 1 semaine d'essai gratuit pour les nouveaux abonnés. Le paiement est débité sur ton identifiant Apple à la confirmation de l'achat ou à la fin de l'essai. L'abonnement se renouvelle automatiquement sauf si le renouvellement est désactivé au moins 24 heures avant la fin de la période en cours ; le renouvellement est facturé dans les 24 heures qui précèdent. Gère ou résilie à tout moment dans les réglages d'abonnement de ton identifiant Apple. Pro reste acquis à ceux qui l'ont.

EXTRAS
• Six encres pour le carnet, chacune avec son icône, 0,99 € pièce
• Impressions de bande à l'unité et packs d'affiches

Sans compte, sans pub, sans pistage. Les écrans de l'app sont en anglais.

Conditions d'utilisation : """ + EULA + """
Confidentialité : """ + PRIVACY

L["fr-FR"] = dict(name="Quiver : tir à l'arc", subtitle="Feuille de marque et viseur",
                  keywords="archerie,flèche,poulies,classique,arc nu,spine,foc,3d,blason,score,chasse,entraînement,club,salle,repère",
                  promo="Ton repère de viseur est maintenant sur l'écran verrouillé. Marque avec une Activité en direct, relève un défi chaque mois et demande n'importe quel repère à Siri.",
                  desc=FR_DESC, notes="""La plus grosse mise à jour de Quiver.

• Ton repère sur l'écran verrouillé, l'écran d'accueil et en StandBy
• Une Activité en direct pour l'épreuve en cours, aussi dans la Dynamic Island
• Demande un repère à Siri ou lance une épreuve depuis le centre de contrôle
• Un nouveau défi chaque mois et tes records personnels
• Quiver Plus : analyses, sauvegarde iCloud, toutes les encres et des affiches chaque mois
• Deux nouvelles encres : Carbon et Marsh

Pro reste un achat unique, et toutes tes données sont conservées.""")

PT_DESC = """Quiver é o caderno de campo do arqueiro: uma súmula que lê o seu agrupamento, uma fita de mira ajustada às marcas que você realmente atirou e a ficha da sua flecha, tudo em papel kraft.

NO CAMPO
• Pontue WA 18 m, WA 70 m, WA 50 m composto, NFAA 300, Vegas 450, percursos 3D ou treino livre
• Toque onde cada flecha caiu no alvo: o Quiver pontua, X incluídos, série a série
• Ele acha o centro do agrupamento e diz quantos milímetros mover a mira
• Atirou com uma marca de mira? Um toque salva a marca corrigida na sua fita
• Um desafio novo todo mês e o seu recorde pessoal em cada rodada
• Compartilhe um pôster da rodada em papel kraft

NA TELA BLOQUEADA
• Widget Marca de mira: a sua marca para qualquer distância, de cinco em cinco com mais e menos na tela de início
• Widgets para a tela bloqueada e o StandBy, e um widget Última rodada com a sua tendência
• Uma Atividade ao Vivo mostra a série e o total na tela bloqueada e na Dynamic Island enquanto você pontua
• Peça a sua marca à Siri ou comece uma rodada pela Central de Controle ou pelo botão de Ação

A FLECHA
• Tubo, ponta, inserto, nock, penas, wrap: peso total, ponto de equilíbrio e FOC desenhados na página
• Energia cinética e momento, comparados às referências para cada caça
• Um spine inicial pela libragem, peso da ponta e comprimento

ARCO E VELOCIDADE
• Velocidade estimada pela velocidade IBO, abertura e peso da flecha, ou pelo seu cronógrafo
• Arrasto pelo diâmetro, peso e penas
• Notas de regulagem para cada equipamento

FITA DE MIRA
• Com duas marcas ou mais, a fita passa por elas com a trajetória modelada, certa também nas distâncias longas
• Leia a marca de qualquer distância com um toque
• Escalas em mm, meio mm, polegadas ou cliques; jardas ou metros
• Imprima em tamanho real em PDF com uma barra de conferência de 10 mm

QUIVER PRO, PAGAMENTO ÚNICO
• Impressões ilimitadas, um equipamento para cada arco, tabela de queda e deriva de 10 a 80 jardas
• Evolução das pontuações, todas as flechas em um alvo, o widget Fita de mira e exportação em planilha

QUIVER PLUS, ASSINATURA
• Tudo do Pro
• Análises: séries finais cansadas, regularidade, tamanho do agrupamento e cada distância
• Backup no iCloud de equipamentos, marcas e rodadas
• Todas as tintas e seus ícones enquanto você assina
• 5 pôsteres por mês e um desafio bônus mais difícil todo mês

O Quiver Plus custa US$ 2,99 por mês ou US$ 14,99 por ano (o preço varia por país), e o plano anual começa com 1 semana grátis para novos assinantes. O pagamento é cobrado no seu ID Apple na confirmação da compra ou ao fim do teste. A assinatura renova automaticamente, a menos que a renovação seja desativada pelo menos 24 horas antes do fim do período atual; a renovação é cobrada nas 24 horas anteriores. Gerencie ou cancele quando quiser nos ajustes de assinaturas do seu ID Apple. Quem tem o Pro continua com ele.

EXTRAS
• Seis tintas para o caderno, cada uma com seu ícone, US$ 0,99 cada
• Impressões avulsas de fita e pacotes de pôsteres

Sem conta, sem anúncios, sem rastreamento. As telas do app são em inglês.

Termos de uso: """ + EULA + """
Política de privacidade: """ + PRIVACY

L["pt-BR"] = dict(name="Quiver: tiro com arco", subtitle="Súmula e marcas de mira",
                  keywords="arquearia,arqueiro,flecha,alvo,composto,recurvo,caça,spine,foc,3d,pontuação,treino,clube,agrupamento,fita",
                  promo="A sua marca de mira agora está na tela bloqueada. Pontue com uma Atividade ao Vivo, encare um desafio novo todo mês e peça qualquer marca à Siri.",
                  desc=PT_DESC, notes="""A maior atualização do Quiver.

• A sua marca de mira na tela bloqueada, na tela de início e no StandBy
• Uma Atividade ao Vivo para a rodada em andamento, também na Dynamic Island
• Peça qualquer marca à Siri ou comece uma rodada pela Central de Controle
• Um desafio novo todo mês e recordes pessoais
• Quiver Plus: análises, backup no iCloud, todas as tintas e pôsteres todo mês
• Duas tintas novas: Carbon e Marsh

O Pro continua sendo pagamento único, e tudo o que você salvou continua aqui.""")

IT_DESC = """Quiver è il taccuino da campo dell'arciere: un segnapunti che legge la tua rosata, una scala del mirino adattata ai riferimenti che hai davvero tirato e la scheda della tua freccia, tutto su carta kraft.

SUL CAMPO
• Segna WA 18 m, WA 70 m, WA 50 m compound, NFAA 300, Vegas 450, percorsi 3D o allenamento libero
• Tocca dove è finita ogni freccia: Quiver la conta, X comprese, volée dopo volée
• Trova il centro della rosata e ti dice di quanti millimetri spostare il mirino
• Hai tirato con un riferimento? Un tocco salva il riferimento corretto sulla tua scala
• Una nuova sfida ogni mese e il tuo record personale per ogni gara
• Condividi un poster della gara su carta kraft

SULLA SCHERMATA DI BLOCCO
• Widget Riferimento: il tuo riferimento per qualsiasi distanza, di cinque in cinque con più e meno dalla schermata Home
• Widget per la schermata di blocco e StandBy, e un widget Ultima gara con il tuo andamento
• Un'Attività in tempo reale mostra volée e totale sulla schermata di blocco e nella Dynamic Island mentre segni
• Chiedi a Siri il tuo riferimento o avvia una gara dal Centro di Controllo o dal tasto Azione

LA FRECCIA
• Asta, punta, inserto, cocca, alette, wrap: peso totale, punto di bilanciamento e FOC disegnati sulla pagina
• Energia cinetica e quantità di moto, confrontate con le indicazioni per la selvaggina
• Uno spine di partenza da libbraggio, peso della punta e lunghezza

ARCO E VELOCITÀ
• Velocità stimata da IBO, allungo e peso della freccia, o dal tuo cronografo
• Resistenza dell'aria da diametro, peso e alette
• Note di messa a punto per ogni setup

SCALA DEL MIRINO
• Con due riferimenti o più, la scala passa da quelli con la traiettoria calcolata: giusta anche sulle lunghe distanze
• Leggi il riferimento di qualsiasi distanza con un tocco
• Scale in mm, mezzi mm, pollici o click; yarde o metri
• Stampala a grandezza reale in PDF con una barra di controllo da 10 mm

QUIVER PRO, UN SOLO PAGAMENTO
• Stampe illimitate, un setup per ogni arco, tabella di caduta e deriva da 10 a 80 yarde
• Andamento dei punteggi, tutte le frecce su un bersaglio, il widget Scala ed esportazione in foglio di calcolo

QUIVER PLUS, ABBONAMENTO
• Tutto Pro
• Analisi: calo nelle ultime volée, costanza, dimensione della rosata nel tempo e ogni distanza
• Backup su iCloud di setup, riferimenti e gare
• Tutti gli inchiostri e le loro icone finché sei abbonato
• 5 poster ogni mese e una sfida bonus più difficile ogni mese

Quiver Plus costa 2,99 € al mese o 14,99 € all'anno (i prezzi variano per paese), e il piano annuale inizia con 1 settimana di prova gratuita per i nuovi abbonati. Il pagamento viene addebitato sul tuo ID Apple alla conferma dell'acquisto o alla fine della prova. L'abbonamento si rinnova automaticamente se il rinnovo non viene disattivato almeno 24 ore prima della fine del periodo in corso; il rinnovo viene addebitato nelle 24 ore precedenti. Gestisci o annulla quando vuoi nelle impostazioni degli abbonamenti del tuo ID Apple. Chi ha Pro lo tiene comunque.

EXTRA
• Sei inchiostri per il taccuino, ognuno con la sua icona, 0,99 € l'uno
• Stampe singole della scala e pacchetti di poster

Nessun account, nessuna pubblicità, nessun tracciamento. Le schermate dell'app sono in inglese.

Termini d'uso: """ + EULA + """
Privacy: """ + PRIVACY

L["it"] = dict(name="Quiver: tiro con l'arco", subtitle="Segnapunti e scala del mirino",
               keywords="arcieri,freccia,bersaglio,compound,olimpico,arco nudo,spine,foc,3d,punteggio,caccia,allenamento,compagnia,rosata",
               promo="Il tuo riferimento ora è sulla schermata di blocco. Segna la gara con un'Attività in tempo reale, affronta una sfida nuova ogni mese e chiedi a Siri ogni riferimento.",
               desc=IT_DESC, notes="""Il più grande aggiornamento di Quiver.

• Il tuo riferimento sulla schermata di blocco, sulla Home e in StandBy
• Un'Attività in tempo reale per la gara in corso, anche nella Dynamic Island
• Chiedi a Siri qualsiasi riferimento o avvia una gara dal Centro di Controllo
• Una nuova sfida ogni mese e i tuoi record personali
• Quiver Plus: analisi, backup su iCloud, tutti gli inchiostri e poster ogni mese
• Due nuovi inchiostri: Carbon e Marsh

Pro resta un acquisto unico e tutti i tuoi dati restano dove sono.""")

JA_DESC = """Quiverは、アーチャーのためのフィールドノートです。グルーピングを読み取るスコアブック、実際に射ったマークを通るようにフィットさせたサイトテープ、そして矢の組み立てシートを、クラフト紙のノートにまとめました。

レンジ
• WA 18m、WA 70m、WA 50mコンパウンド、NFAA 300、ベガス450、3Dコース、自由練習を採点
• 矢が当たった場所を的の上でタップするだけ。Xも含めて、エンドごとに採点します
• グルーピングの中心を見つけ、サイトを何ミリ動かせばいいかを表示
• サイトマークで射ったラウンドなら、補正したマークをワンタップでテープに保存
• 毎月新しいチャレンジ。ラウンドごとの自己ベストも記録
• クラフト紙のスコアカードポスターでラウンドをシェア

ロック画面に
• サイトマークウィジェット:どの距離のマークも、ホーム画面のプラスとマイナスで5ずつ切り替え
• ロック画面とスタンバイ用のウィジェット、前回のラウンドと推移を表示するウィジェット
• 採点中は、ライブアクティビティがエンドと合計をロック画面とダイナミックアイランドに表示
• Siriにサイトマークを聞いたり、コントロールセンターやアクションボタンからラウンドを始めたり

矢
• シャフト、ポイント、インサート、ノック、ベイン、ラップから総重量、重心、FOCを図示
• 運動エネルギーと運動量を獲物ごとの目安と比較
• ドローウェイト、ポイント重量、長さからスパインの目安

弓とスピード
• 公称スピード、引き尺、矢の重さから速度を推定。クロノグラフの実測値も使えます
• 直径、重さ、ベインから空気抵抗を計算
• セットアップごとのチューニングメモ

サイトテープ
• マークを2つ以上入力すると、弾道モデルでそれらを通るテープを作成。遠い距離まで正確です
• どの距離のマークもワンタップで
• mm、0.5mm、インチ、クリックの目盛り。ヤードでもメートルでも
• 10mmの確認バー付きPDFで原寸大に印刷

QUIVER PRO(買い切り)
• テープ印刷が無制限、弓ごとのセットアップ、10〜80ヤードのドロップとドリフト表
• スコアの推移、すべての矢を1つの的に、サイトテープウィジェット、スプレッドシート書き出し

QUIVER PLUS(サブスクリプション)
• Proのすべて
• 分析:後半のエンドの落ち込み、安定度、グルーピングの大きさの推移、距離ごとの成績
• セットアップ、マーク、すべてのラウンドをiCloudにバックアップ
• 購読中はすべてのインクとアプリアイコンを利用可能
• 毎月5枚のスコアカードポスターと、毎月のボーナスチャレンジ

Quiver Plusは月額2.99ドルまたは年額14.99ドル相当(国や地域により価格は異なります)。年額プランは新規登録者向けに1週間の無料トライアル付きです。お支払いは購入確定時、または無料トライアル終了時にApple IDに請求されます。現在の期間が終わる24時間以上前に自動更新をオフにしない限り、サブスクリプションは自動で更新され、期間終了前の24時間以内に更新料金が請求されます。管理や解約はApple IDのサブスクリプション設定からいつでも行えます。Proをお持ちの方はProをそのままお使いいただけます。

追加アイテム
• 6色のノートインク(それぞれ専用アイコン付き)
• テープ1回分の印刷とポスターのパック

アカウント不要、広告なし、トラッキングなし。※アプリ内の表示は英語です。

利用規約: """ + EULA + """
プライバシーポリシー: """ + PRIVACY

L["ja"] = dict(name="Quiver: アーチェリーのスコア記録", subtitle="サイトマークと矢の設定、グルーピング分析",
               keywords="弓,洋弓,コンパウンド,リカーブ,スパイン,的,点数表,採点,スコアブック,サイトテープ,ベガス,ボウハンティング,狩猟,練習,アロー,照準,ウィジェット",
               promo="サイトマークがロック画面に。ライブアクティビティでラウンドを採点し、毎月のチャレンジに挑戦。Siriに聞けばどの距離のマークもすぐわかります。",
               desc=JA_DESC, notes="""Quiver史上最大のアップデート。

• サイトマークをロック画面、ホーム画面、スタンバイに
• 採点中のラウンドをライブアクティビティとダイナミックアイランドに表示
• Siriでマークを確認、コントロールセンターからラウンド開始
• 毎月の新しいチャレンジと、ラウンドごとの自己ベスト
• Quiver Plus:分析、iCloudバックアップ、すべてのインク、毎月のポスター
• 新しいインク2色:CarbonとMarsh

Proは買い切りのまま。入力したデータはすべて引き継がれます。""")

KO_DESC = """Quiver는 궁사를 위한 필드 노트입니다. 그룹을 읽어 주는 점수 기록장, 실제로 쏜 마크를 지나도록 맞춘 사이트 테이프, 화살 세팅 시트를 크라프트지 노트 한 권에 담았습니다.

사로에서
• WA 18m, WA 70m, WA 50m 컴파운드, NFAA 300, 베가스 450, 3D 코스, 자유 연습 채점
• 과녁에서 화살이 맞은 자리를 탭하면 X까지 엔드별로 채점
• 그룹의 중심을 찾아 사이트를 몇 mm 옮길지 알려 줍니다
• 사이트 마크로 쏜 라운드라면 보정된 마크를 한 번에 테이프에 저장
• 매달 새로운 챌린지와 라운드별 개인 최고 기록
• 크라프트지 점수 포스터로 라운드 공유

잠금 화면에서
• 사이트 마크 위젯: 홈 화면에서 플러스와 마이너스로 5씩 거리를 바꾸며 마크 확인
• 잠금 화면과 스탠바이 위젯, 지난 라운드와 추세를 보여 주는 위젯
• 채점하는 동안 실시간 현황이 엔드와 합계를 잠금 화면과 다이내믹 아일랜드에 표시
• Siri에게 사이트 마크를 묻거나 제어 센터와 동작 버튼으로 라운드 시작

화살
• 샤프트, 포인트, 인서트, 노크, 베인, 랩으로 총 무게, 무게 중심, FOC를 그려 줍니다
• 운동 에너지와 운동량을 사냥감별 기준과 비교
• 드로 웨이트, 포인트 무게, 길이로 스파인 출발점 제시

활과 속도
• 정격 속도, 드로 길이, 화살 무게로 속도 추정, 크로노그래프 값도 사용 가능
• 지름, 무게, 베인으로 공기 저항 계산
• 세팅별 튜닝 메모

사이트 테이프
• 마크를 두 개 이상 입력하면 탄도 모델로 그 마크를 지나는 테이프를 만들어 먼 거리까지 정확
• 어떤 거리의 마크도 한 번에 확인
• mm, 0.5mm, 인치, 클릭 눈금, 야드와 미터
• 10mm 확인 막대가 있는 PDF로 실제 크기 인쇄

QUIVER PRO (한 번 결제)
• 무제한 테이프 인쇄, 활마다 세팅, 10~80야드 낙차와 편류 표
• 점수 추세, 모든 화살을 한 과녁에, 사이트 테이프 위젯, 스프레드시트 내보내기

QUIVER PLUS (구독)
• Pro의 모든 기능
• 분석: 후반 엔드의 하락, 일관성, 그룹 크기의 변화, 거리별 성적
• 세팅, 마크, 모든 라운드를 iCloud에 백업
• 구독 중에는 모든 잉크와 앱 아이콘 사용
• 매달 점수 포스터 5장과 더 어려운 보너스 챌린지

Quiver Plus는 월 2.99달러 또는 연 14.99달러 상당이며(국가별로 가격이 다릅니다), 연간 플랜은 신규 구독자에게 1주 무료 체험으로 시작합니다. 결제는 구매 확인 시 또는 무료 체험 종료 시 Apple ID로 청구됩니다. 현재 기간이 끝나기 최소 24시간 전에 자동 갱신을 끄지 않으면 구독은 자동으로 갱신되며, 기간 종료 전 24시간 이내에 갱신 요금이 청구됩니다. Apple ID의 구독 설정에서 언제든 관리하거나 해지할 수 있습니다. Pro를 가진 분은 Pro를 계속 사용합니다.

추가 아이템
• 노트 잉크 6가지, 각각 전용 앱 아이콘
• 테이프 1회 인쇄와 포스터 팩

계정 없음, 광고 없음, 추적 없음. 앱 화면은 영어입니다.

이용 약관: """ + EULA + """
개인정보 처리방침: """ + PRIVACY

L["ko"] = dict(name="Quiver: 양궁 점수표와 사이트 테이프", subtitle="화살 세팅과 조준기 마크를 한 번에",
               keywords="활,컴파운드,리커브,스파인,과녁,채점,베가스,사냥,활사냥,연습,그룹,조준,타깃,탄도,애로우,활쏘기,양궁장,점수,기록,위젯,챌린지",
               promo="사이트 마크가 잠금 화면에. 실시간 현황으로 라운드를 채점하고 매달 새로운 챌린지에 도전하세요. Siri에게 물으면 어떤 거리의 마크든 알려 줍니다.",
               desc=KO_DESC, notes="""Quiver 역대 최대 업데이트.

• 사이트 마크를 잠금 화면, 홈 화면, 스탠바이에
• 채점 중인 라운드를 실시간 현황과 다이내믹 아일랜드에
• Siri로 마크 확인, 제어 센터에서 라운드 시작
• 매달 새로운 챌린지와 라운드별 개인 최고 기록
• Quiver Plus: 분석, iCloud 백업, 모든 잉크, 매달 포스터
• 새로운 잉크 2가지: Carbon, Marsh

Pro는 여전히 한 번 결제이며, 입력한 데이터는 모두 그대로입니다.""")

ZH_DESC = """Quiver 是弓箭手的野外笔记本:能读懂箭组的计分本、按你实际射出的瞄点拟合的瞄准刻度带,还有箭支配置表,全都在牛皮纸笔记本里。

在靶场
• 为 WA 18 米、WA 70 米、WA 50 米复合弓、NFAA 300、Vegas 450、3D 路线或自由练习计分
• 点按每支箭在靶面上的落点:Quiver 逐组计分,X 环也算
• 找出箭组中心,告诉你瞄具该移动多少毫米
• 用瞄点射的这一轮?点一下就把修正后的瞄点存进刻度带
• 每月一个新挑战,每种轮次都记录个人最佳
• 分享牛皮纸风格的计分海报

在锁定屏幕上
• 瞄点小组件:在主屏幕用加减按钮每次调整 5,随时查看任意距离的瞄点
• 锁定屏幕和待机显示小组件,以及显示上一轮和走势的小组件
• 计分时,实时活动在锁定屏幕和灵动岛上显示当前组和总分
• 问 Siri 你的瞄点,或从控制中心和操作按钮开始新的一轮

箭支
• 箭杆、箭头、插销、箭尾、羽片、箭贴:总重、平衡点和 FOC,画在页面上
• 动能和动量,对照不同猎物的参考值
• 根据拉力、箭头重量和长度给出箭杆硬度的起点

弓和速度
• 根据标称速度、拉距和箭重估算速度,也可以填测速仪数据
• 根据直径、重量和羽片计算空气阻力
• 每套配置的调弓笔记

瞄准刻度带
• 输入两个以上瞄点,用弹道模型拟合出经过它们的刻度带,远距离也准确
• 一点就能读出任意距离的瞄点
• 毫米、半毫米、英寸或点击刻度;码或米
• 以实际尺寸打印 PDF,附 10 毫米校验条

QUIVER PRO(一次性购买)
• 无限次打印刻度带、每把弓一套配置、10 至 80 码下坠与偏移表
• 成绩走势、所有箭落在一张靶面上、刻度带小组件、导出电子表格

QUIVER PLUS(订阅)
• 包含 Pro 的全部功能
• 数据分析:后段组的下滑、稳定性、箭组大小的变化、各距离表现
• 将配置、瞄点和所有轮次备份到 iCloud
• 订阅期间可使用全部墨色和对应的 App 图标
• 每月 5 张计分海报,以及每月一个更难的附加挑战

Quiver Plus 每月约 2.99 美元或每年约 14.99 美元(价格因国家或地区而异),年度方案为新订阅者提供 1 周免费试用。确认购买时或免费试用结束时,将从你的 Apple ID 扣款。除非在当前周期结束前至少 24 小时关闭自动续订,订阅会自动续订,并在周期结束前 24 小时内扣除续订费用。你可以随时在 Apple ID 的订阅设置中管理或取消。已拥有 Pro 的用户将继续保留 Pro。

附加内容
• 6 种笔记本墨色,各自带有专属图标
• 单次刻度带打印和海报包

无需账号,没有广告,没有追踪。App 界面为英文。

使用条款:""" + EULA + """
隐私政策:""" + PRIVACY

L["zh-Hans"] = dict(name="Quiver: 射箭计分 瞄准刻度", subtitle="记录瞄点与箭组,算好箭支FOC",
                    keywords="射箭,弓箭,复合弓,反曲弓,传统弓,箭杆,箭杆硬度,靶,靶纸,记分卡,弓猎,狩猎,练习,瞄具,射程,3D射箭,射箭馆,计分,射箭训练,小组件,挑战",
                    promo="瞄点现在显示在锁定屏幕上。用实时活动为一轮计分,每月挑战新目标,问 Siri 就能得到任意距离的瞄点。",
                    desc=ZH_DESC, notes="""Quiver 迄今最大的更新。

• 瞄点显示在锁定屏幕、主屏幕和待机显示
• 正在计分的一轮会显示在实时活动和灵动岛
• 问 Siri 任意瞄点,或从控制中心开始一轮
• 每月新挑战,以及每种轮次的个人最佳
• Quiver Plus:数据分析、iCloud 备份、全部墨色和每月海报
• 两种新墨色:Carbon 和 Marsh

Pro 仍是一次性购买,你输入的一切都会保留。""")

LIMITS = {"name": 30, "subtitle": 30, "keywords": 100, "promo": 170, "desc": 4000, "notes": 4000}
FILES = {"name": "name.txt", "subtitle": "subtitle.txt", "keywords": "keywords.txt", "promo": "promotional_text.txt",
         "desc": "description.txt", "notes": "release_notes.txt"}
PRICE_WORDS = ["$", "€", "free", "gratis", "gratuit", "grátis", "無料", "무료", "免费", "price", "precio", "preis", "prix", "preço", "prezzo", "subscription"]


def main():
    bad = False
    for loc, m in L.items():
        # Drop words from the end until the keyword field fits.
        kws = m["keywords"].split(",")
        while len(",".join(kws)) > 100:
            kws.pop()
        m["keywords"] = ",".join(kws)
        d = ROOT / loc
        d.mkdir(parents=True, exist_ok=True)
        for k, fn in FILES.items():
            v = m[k]
            if len(v) > LIMITS[k]:
                print(f"{loc} {k}: {len(v)} > {LIMITS[k]}"); bad = True
            (d / fn).write_text(v + "\n", encoding="utf-8", newline="\n")
        for k in ("support_url", "marketing_url"):
            (d / f"{k}.txt").write_text(URL + "\n", encoding="utf-8", newline="\n")
        (d / "privacy_url.txt").write_text(PRIVACY + "\n", encoding="utf-8", newline="\n")
        # Keywords must not repeat words already in the name or subtitle.
        words = set((m["name"] + " " + m["subtitle"]).lower().replace(":", " ").replace(",", " ").replace("&", " ").split())
        rep = [w for w in m["keywords"].lower().split(",") if w in words]
        if rep:
            print(f"{loc} keywords repeat name/subtitle: {rep}")
        for k in ("promo", "subtitle", "name"):
            hit = [w for w in PRICE_WORDS if w.lower() in m[k].lower()]
            if hit:
                print(f"{loc} {k} has price words {hit}"); bad = True
        if "—" in "".join(m.values()):
            print(f"{loc}: em dash"); bad = True
        print(f"{loc}: name {len(m['name'])} sub {len(m['subtitle'])} kw {len(m['keywords'])} promo {len(m['promo'])} desc {len(m['desc'])}")
    print("FAILED" if bad else "ok")


if __name__ == "__main__":
    main()
