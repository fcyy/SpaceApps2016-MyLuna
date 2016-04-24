# SpaceApps2016-MyLuna
Entry for Space Apps 2016 Hackathon under challenge "Book it to the Moon"

MyLuna is a virtual-reality capable iPad app for children and anyone who's 
curious to know about Earth's lone natural satellite , the Moon. Users will 
either hold the iPad or mount it on VR headgear like the AirVR with its back 
facing the sky, and find the moon by following the directional arrows 
on-screen. Once the iPad has been oriented with sufficient accuracy as to bring 
the moon into view on the screen, the user fine tunes the orientation, 
attempting to position the moon in the centre of the screen where a net is waiting 
to capture it. Once captured, the moon is locked and the screen fades out to reveal 
multimedia panes.

These multimedia panes are interactive text, video, graphics shipped with the app
and from all over the internet. In the prototype app, the panes have static content,
serving only to illustrate the concept.

The prototype app submitted in this challenge contains a fully functional algorithm
to locate the moon in the sky, as can be seen from the video. The app uses positional
astronomy to determine the moon's altitude and azimuth from the user’s location and
current time. These are converted into screen coordinates, positioning a representation
of the moon in the center of the screen when the Apple logo on the back of the iPad is
pointed directly at the moon.

## RESOURCES USED
Computing Planetary Positions (http://stjarnhimlen.se/comp/ppcomp.html)

Mooncalc.org (to test app locator logic - PASSED :)

4 arcminute moon position algorithm (www.stargazing.net)

Converting right ascension/declination to azimuth/altitude (http://www.stargazing.net/kepler/altaz.html)

iOS documentation (especially Core Motion, Core Location)

NASA website on the Moon (snipped some pics as demo content for the app)
