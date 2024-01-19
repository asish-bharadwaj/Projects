#!/usr/bin/python3

from flask import Flask, request, jsonify, render_template, redirect, url_for
from flask_cors import CORS
import json

app = Flask(__name__)

@app.route('/')
def index():
    return render_template("./index.html")

@app.route('/submit-form', methods=['POST'])
def post_request():
    name = request.form.get("name")
    mail = request.form.get("mail")
    password = request.form.get("password")
    
    with open("users.txt", "a") as f:
        data = {'name': name, 'mail':mail, 'password': password}
        json.dump(data, f)
        f.write('\n')

    return redirect('/print_current_data?name=' + name + '&mail=' + mail + '&password=' + password)

@app.route('/print_current_data')
def show_details():
    name = request.args.get('name')
    mail = request.args.get('mail')
    password = request.args.get('password')
    data = "Name: " + name + "<br>Mail: " + mail + "<br>Password: " + password + "<br>"
    return data

@app.route('/get-request', methods=['GET'])
def get_data():
    data = []
    with open("users.txt", "r") as f:
        for line in f:
            data.append(json.loads(line))
            
    return data

if __name__ == '__main__':
    app.run(debug=True)