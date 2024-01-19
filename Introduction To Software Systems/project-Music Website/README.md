SonicSphere

Music reviews and ratings, all in one place

“SonicSphere” is a web portal for an Internet Music Database. Currently, the website has information about various artists (8 in total), albums (5 per artist), and songs (5 per album).

<<<< How to Host the website>>>>

    • Inside the Directory "ISSproject1" run the "app.py" Python file to start a local server.Use the URL to go to Website.
    • Make sure to have "templates" - contains all html files for website, "static" - contains all css and js files, "playlist.db" - Database of songs in the Directory in which app.py is running.
      
The Directory-ISS_project1 Structure:

    • This main Directory(ISS_project1) contains the HTML files for Home, Artists, Albums, About, Privacy Policy, and Terms of Service pages as Home.html,Artists.html, etc, and Style.css file.
    • It contains an "Albums" Directory in it, Which contains HTML files for Album pages of individual Artists(Ed_SheeranAlbum.html, Imagine_DragonsAlbums.html, ..etc).
    • The Albums Directory also contains a few other Directories such as "Ed_SheeranAlbums", "Imagine_DragonsAlbumss", and so on which contains HTML files of songs pages for corresponding Artist & Album. 
    • The "Ed_SheeranAlbums" Directory contains HTML files of Songs pages of respective Albums such as Divide_Deluxe.html, Plus.html, and so on. Similarly in all other Directories inside the "Albums" Directory.
    • Every HTML file is linked with Style.css to style and layout webpages.

The description of the website is as follows:

Home Page:

    •  At the top is the name and logo of the website, followed by the navigation bar.
    •  After the navigation bar is the Top Charts content with three sections: Top Artists, Top Albums, and Top Songs, each displaying 3 items of the corresponding section.
    •  The Top Artists section contains circular clickable images of the artists/bands, along with the name of the artists/bands as a caption, in a row.
    •  When the cursor/pointer hovers over the image/name of the artist/band, the image is scaled to 1.2x times, and clicking on it redirects to the page listing albums of the chosen artist/band.
    •  The Top Albums section contains images and names of the albums, in the same format as that of images in Top Artists section. Clicking on an album redirects to the page listing songs of the chosen album.
    •  The Top Songs section contains the top three songs in a row. Each song’s information is displayed with a cover image of the song followed by name of the song, the name of the artist/band, and the duration of the song.
    •  To the bottom right corner is the ‘Back To Top’ clickable image of an upward arrow. Clicking on it slides to the top of the current page.
    •  At the end is the footer.
      
Navigation Bar:

    •  Every web page has a slightly transparent persistent navigation bar, which contains the logo and name of the website to the left and links to Home, Artists, Albums, and About pages to the right.
    •  Clicking on the logo or name of the website from any web page redirects to the Home webpage.
    •  Clicking on any of the pages displayed to the right of the navigation bar redirects to the corresponding web page.
    •  Hovering over the web page names changes the background color of the block containing the name of the corresponding web page to gray shade and the text color to white.
    •  Charcoal Background color is used as a display indicator/ virtual cue to indicate the current web page.

Footer:

    •  A small, consistent footer is displayed at the end of every page.
    •  It contains the logo and name of the website to the right. It is clickable and clicking on it redirects to the Home page.
    •  To the right of the website name, there are 5 links, clicking on any of them redirects to the corresponding page:

    1.  Home
    2.  About Us
    3.  Contact
    4.  Privacy Policy
    5.  Terms of Service
    • At the end is the copyright.

Artists page:

    •  It has the navigation bar on the top followed by the heading – “Artists”
    •  The heading is followed by symmetrically placed clickable images of 8 artists/bands (format same as that of the artists in the Top Artists section of the Home page, mentioned above):

    1.      Ed Sheeran    
    2.      One Direction    
    3.      Katy Perry    
    4.      Taylor Swift    
    5.      Imagine Dragons    
    6.      Justin Bieber    
    7.      Lorde    
    8. Shawn Mendes    
    • Clicking on the artist/band image redirects to the Albums page of the corresponding artist/band.
    • To the bottom right corner is the Back to Top arrow. At the end is the footer.

Albums page:

    • It has the navigation bar on the top followed by all artists/bands. Each artist/band’s section contains a wide aspect ratio image of the artist/band along with their name, with a fixed background-attachment.
    • Five albums of the corresponding artist/band are displayed as symmetrically placed circular clickable album cover images. (properties similar to the artists’ images as mentioned before)
    • The description of the album (name, number of songs, and year of release) is displayed at the bottom of the corresponding album's cover image within a slightly transparent block.
    • Clicking on the cover image of an album redirects to the Songs page of that album.
    • The description of the album is not clickable.
    • To the bottom right corner is the Back to Top arrow. At the end is the footer.

About page:

    •  It has the navigation bar on the top, followed by the About Us section, containing a brief description of the website, such as purpose, features, etc., and details of its creators such as name, email, image, etc.
    •  At the end is the footer.

Search Page:

    •  It has a navigation bar on the top followed by the heading – “Search”
    •  The heading is followed by the search bar. A search non-clickable symbol is placed at the leftmost end of the searchbar. The searchbar contains the placeholder – “What do you want to listen to?”
    •  When some input is typed in the search bar; only then a clear button (times symbol) is displayed on the rightmost corner of the searchbar. It is a clickable image; and clicking on it clears the contents of searchbar.
    •  Beneath the searchbar is the “Filters” options. There are two filter options:
    1.   Based on maximum duration of the song  
    2. Explicitness  
    • The maximum duration filter is provided with a slider. By default; it is set to 10 minutes (600 seconds). One can slide it ranging from 0 to 10 minutes through steps of 1 second. The slider value is displayed to the right of the slider; for user convenience. Whenever the slider value is changed to a value other than the default value of 10 minutes; a clear button (times symbol) is displayed to the right of the slider value. It is a clickable image; and clicking on it will set the slider to default duration of 10 minutes.
    • Beside the duration slider, is the explicitness checkbox. Checking it will include explicit results. Beside it, a clear-all button (times symbol) is displayed. It is a clickable image; and clicking on it will clear both the filters, meaning sets duration to default of 10 minutes and dechecks the explicit checkbox.
    • Based on the search results; a maximum of 10 results are displayed one after the other as a list, each enclosed in a box.
    • Each result element has the album image to the right; Details of the song (Song name, Album, Artist) to the right of the image and an audio control system at the bottom.In Songs Page of each Album, added a "Add to Playlist" Button to add that song to playlist

Playlist Page:

    • It contains the Songs which were added to playlists with a button-"Remove from Playlist" to remove from playlist.
      
    • Whenever refreshed, songs from playlist table are displayed.

app.py:

    • the app.py file serves as the entry point to the web application and coordinates the various components of the application, including handling incoming requests, processing data, and generating responses to send back to the user. It typically imports other modules and components of the application and starts the server that listens for incoming requests.
      
    • Used flask,sqlite3

playlist.db:

    • This database contains two Tables - "playlist" and "songs"
      
    • "songs" table is used to store all the songs used in website with columns - "id","song","min","sec","artist" to hold required information.
      
    • "playlist" table is used to store all the songs added to playlist using buttons in songs Page using Unique id for each song
      
    • when "Add to Playlist" is pressed, a new row is inserted to playlist table from songs table using Unique id
      
    • when "Remove from Playlist" is pressed, the row with corresponding Unique id is deleted from table
