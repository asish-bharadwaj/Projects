import sqlite3
from flask import Flask, render_template, request,jsonify,redirect,url_for

app = Flask(__name__,static_url_path='/static')
@app.route('/',  methods=['POST','GET'])
def home():
    return render_template('Home.html')
@app.route('/Album')
def Album():
    return render_template('Albums.html')
@app.route('/Artists')
def Artists():
    return render_template('Artists.html')
@app.route('/ArtistSpotlight')
def ArtistSpotlight():
    return render_template('/ArtistSpotlight.html')
@app.route('/About')
def About():
    return render_template('/About.html')
@app.route('/Search')
def Search():
    return render_template('/search.html')
@app.route('/Privacy_policy')
def Privacy_policy():
    return render_template('/Privacy_policy.html')
@app.route('/Terms_of_service')
def Terms_of_service():
    return render_template('/Terms_of_service.html')

conn=sqlite3.connect('playlist.db')
c=conn.cursor()
c.execute(f"CREATE TABLE IF NOT EXISTS songs(id INTEGER,song TEXT,min INTEGER,sec INTEGER,artist TEXT)")
c.execute(f"CREATE TABLE IF NOT EXISTS playlist(id INTEGER,song TEXT,min INTEGER,sec INTEGER,artist TEXT)")
conn.commit()
c.close()
conn.close()

@app.route('/Playlist')
def retrive():
    # referrer = request.referrer
    # # print(referrer)
    # # Extract the filename from the URL
    # filename = referrer.split('/')[-1]
    conn=sqlite3.connect('playlist.db')
    cursor = conn.cursor()
    d=()
    dic={}
    d=cursor.execute('SELECT * FROM playlist')
    for x in d:
        dic[x[0]]=[x[1]]
        dic[x[0]]+=[x[2]]
        dic[x[0]]+=[x[3]]
        dic[x[0]]+=[x[4]]
    # print(dic)
    
    return render_template('Playlist.html', dic=dic)
@app.route('/Playlist')
def Playlist():
    return render_template('/Playlist.html')
@app.route('/Ed_Sheeran')
def Ed_Sheeran():
    return render_template('/Albums/Ed_SheeranAlbum.html')
@app.route('/Ed_sheeranSpotlight')
def Ed_sheeranSpotlight():
    return render_template('/Albums/Ed_sheeranSpotlight.html')
@app.route('/Imagine_dragons')
def Imagine_dragons():
    return render_template('/Albums/Imagine_dragonsAlbums.html')
@app.route('/Justin_Bieber')
def Justin_Bieber():
    return render_template('/Albums/Justin_BieberAlbums.html')
@app.route('/Katy_Perry')
def Katy_Perry():
    return render_template('/Albums/Katy_PerryAlbums.html')
@app.route('/Lorde')
def Lorde():
    return render_template('/Albums/LordeAlbums.html')
@app.route('/One_direction')
def One_direction():
    return render_template('/Albums/One_directionAlbums.html')
@app.route('/Shawn_Mendes')
def Shawn_Mendes():
    return render_template('/Albums/Shawn_MendesAlbums.html')
@app.route('/Taylor_Swift')
def Taylor_Swift():
    return render_template('/Albums/Taylor_SwiftAlbums.html')



















@app.route('/Divide')
def Divide():
    return render_template('/Albums/Ed_SheeranAlbumss/Divide_Delux.html')
@app.route('/equal')
def equal():
    return render_template('/Albums/Ed_SheeranAlbumss/equal.html')
@app.route('/multiply')
def multiply():
    return render_template('/Albums/Ed_SheeranAlbumss/mutiply.html')
@app.route('/No6_Collaborations')
def No6_Collaborations():
    return render_template('/Albums/Ed_SheeranAlbumss/No.6_Collaborations_project.html')
@app.route('/Plus')
def Plus():
    return render_template('/Albums/Ed_SheeranAlbumss/Plus.html')
@app.route('/Evolve')
def Evolve():
    return render_template('/Albums/Imagine_dragonsAlbumss/Evolve.html')
@app.route('/Mercury')
def Mercury():
    return render_template('/Albums/Imagine_dragonsAlbumss/Mercury_act1&2.html')
@app.route('/Night_Vision')
def Night_Vision():
    return render_template('/Albums/Imagine_dragonsAlbumss/Night_vision.html')
@app.route('/Origins')
def Origins():
    return render_template('/Albums/Imagine_dragonsAlbumss/Origins.html')
@app.route('/SmokeMirrors')
def SmokeMirrors():
    return render_template('/Albums/Imagine_dragonsAlbumss/smoke+Mirrors.html')
@app.route('/Believe')
def Believe():
    return render_template('/Albums/Justin_BieberAlbumss/Believe.html')
@app.route('/Journals')
def Journals():
    return render_template('/Albums/Justin_BieberAlbumss/Journals.html')
@app.route('/Justice')
def Justice():
    return render_template('/Albums/Justin_BieberAlbumss/Justice.html')
@app.route('/My_world')
def My_world():
    return render_template('/Albums/Justin_BieberAlbumss/My_world.html')
@app.route('/Purpose')
def Purpose():
    return render_template('/Albums/Justin_BieberAlbumss/Purpose.html')
@app.route('/one_of_the_boys')
def one_of_the_boys():
    return render_template('/Albums/Katy_perryAlbumss/one_of_the_boys.html')
@app.route('/Prism')
def Prism():
    return render_template('/Albums/Katy_perryAlbumss/Prism.html')
@app.route('/Smile')
def Smile():
    return render_template('/Albums/Katy_perryAlbumss/Smile.html')
@app.route('/Teenage_dream')
def Teenage_dream():
    return render_template('/Albums/Katy_perryAlbumss/Teenage_dream.html')
@app.route('/witness')
def witness():
    return render_template('/Albums/Katy_perryAlbumss/witness.html')
@app.route('/Melodrama')
def Melodrama():
    return render_template('/Albums/LordeAlbumss/Melodrama.html')
@app.route('/Pure_heroine')
def Pure_heroine():
    return render_template('/Albums/LordeAlbumss/Pure_heroine.html')
@app.route('/Sunpower')
def Sunpower():
    return render_template('/Albums/LordeAlbumss/Sunpower.html')
@app.route('/te_Ao_Marama')
def te_Ao_Marama():
    return render_template('/Albums/LordeAlbumss/te_Ao_Marama.html')
@app.route('/The_love_club_EP')
def The_love_club_EP():
    return render_template('/Albums/LordeAlbumss/The_love_club_EP.html')
@app.route('/Four')
def Four():
    return render_template('/Albums/One_directionAlbuss/Four.html')
@app.route('/Made_in_the_Am')
def Made_in_the_Am():
    return render_template('/Albums/One_directionAlbuss/Made_in_the_Am.html')
@app.route('/Midnight_memories')
def Midnight_memories():
    return render_template('/Albums/One_directionAlbuss/Midnight_memories.html')
@app.route('/Take_me_home')
def Take_me_home():
    return render_template('/Albums/One_directionAlbuss/Take_me_home.html')
@app.route('/Up_All_night')
def Up_All_night():
    return render_template('/Albums/One_directionAlbuss/Up_All_night.html')
@app.route('/Handwritten')
def Handwritten():
    return render_template('/Albums/Shawn_MendesAlbumss/Handwritten.html')
@app.route('/Illuminate')
def Illuminate():
    return render_template('/Albums/Shawn_MendesAlbumss/Illuminate.html')
@app.route('/MTV_Unplugged')
def MTV_Unplugged():
    return render_template('/Albums/Shawn_MendesAlbumss/MTV_Unplugged.html')
@app.route('/Shawn_Mendess')
def Shawn_Mendess():
    return render_template('/Albums/Shawn_MendesAlbumss/Shawn_Mendes.html')
@app.route('/Wonder')
def Wonder():
    return render_template('/Albums/Shawn_MendesAlbumss/Wonder.html')
@app.route('/i1989')
def i1989():
    return render_template('/Albums/Taylor_SwiftAlbumss/1989.html')
@app.route('/Evermore')
def Evermore():
    return render_template('/Albums/Taylor_SwiftAlbumss/Evermore.html')
@app.route('/fearless')
def fearless():
    return render_template('/Albums/Taylor_SwiftAlbumss/fearless.html')
@app.route('/Midnights')
def Midnights():
    return render_template('/Albums/Taylor_SwiftAlbumss/Midnights.html')
@app.route('/Red')
def Red():
    return render_template('/Albums/Taylor_SwiftAlbumss/Red.html')






@app.route('/retrive_id', methods=['POST'])

def retrieve_id():
    id = request.form['id']
    
    referrer = request.referrer
    # print(referrer)
    # Extract the filename from the URL
    filename = referrer.split('/')[-1]
    # print(filename)
    # Do something with the ID
    conn=sqlite3.connect('playlist.db')
    cursor = conn.cursor()
    
    y=0
    d=cursor.execute('SELECT id FROM playlist WHERE id=?', (id,))
    for i in d:
        for x in i:
            y=x
    if y==0:
        cursor.execute('SELECT * FROM songs WHERE id = ?', (id,))
        row = cursor.fetchone()

    # INSERT the row into table2
        cursor.execute('INSERT INTO playlist VALUES (?, ?, ?,?,?)', row)
        conn.commit()
    
        
# SELECT the row to be moved from table1
    

    # DELETE the row from table1
    # cursor.execute('DELETE FROM table1 WHERE id = ?', (1,))

    # Commit the transaction
   

    # Close the cursor and the database connection
    cursor.close()
    conn.close()
   

    # return 'Retrieved ID {}'.format(id)
    return redirect(url_for(filename))
    
@app.route('/remove', methods=['POST'])
def remove():
    id = request.form['id']
    print(id)
    referrer = request.referrer
    # print(referrer)
    # Extract the filename from the URL
    filename = referrer.split('/')[-1]

    conn=sqlite3.connect('playlist.db')
    cursor = conn.cursor()
    cursor.execute('DELETE FROM playlist WHERE id = ?', (id,))
    conn.commit()
    cursor.close()
    conn.close()



    return redirect(url_for(filename))


if __name__=='__main__':
    app.run(debug=True)