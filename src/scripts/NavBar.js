import React from 'react';
//import jQuery from 'jquery'
//import Bootstrap from 'bootstrap'
window.$ = window.jQuery = require('jquery');
var Bootstrap = require('bootstrap');
Bootstrap.$ = $;


export default class NavBar extends React.Component {
    constructor() {
        super()
        this.onLogout  = this.onLogout.bind(this)
        this.onCloseDB = this.onCloseDB.bind(this)
    }

    onLogout() {
        KeePass4Web.logout(this.props.router)
    }

    onCloseDB () {
        KeePass4Web.closeDB(this.props.router)
    }

    componentDidMount() {
        if (KeePass4Web.getCN()) {
            document.getElementById('logout').addEventListener('click', this.onLogout)
            document.getElementById('closeDB').addEventListener('click', this.onCloseDB)
        }
    }

    render() {
        var cn = KeePass4Web.getCN()
        var dropdown, search
        if (cn) {
            dropdown = (
                <ul className="dropdown-menu">
                    <li><a id="logout" href="#">Logout</a></li>
                    <li role="separator" className="divider"></li>
                    <li><a id="closeDB" href="#">Close Database</a></li>
                    <li><a id="saveDB" href="#">Save Database</a></li>
                </ul>
            )
        }
        else {
            cn = 'Not logged in'
            dropdown = (
                <ul className="dropdown-menu">
                    <li><a href="#/">Login</a></li>
                </ul>
            )
        }

        if (this.props.showSearch) {
            search =  (
                <form className="navbar-form navbar-left" onSubmit={this.props.onSearch.bind(this, this.refs)}>
                    <div className="form-group">
                        <input autoComplete="on" type="search" ref="term" className="form-control" placeholder="Search" autoFocus="autoFocus" />
                    </div>
                    <button type="submit" className="btn btn-default">Submit</button>
                </form>
            )
        }

        return (
            <nav className="navbar navbar-default navbar-fixed-top">
                <div className="navbar-header">
                    <button type="button" className="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar-collapse-1" aria-expanded="false">
                        <span className="sr-only">Toggle navigation</span>
                        <span className="icon-bar"></span>
                        <span className="icon-bar"></span>
                        <span className="icon-bar"></span>
                    </button>
                    <a className="navbar-brand" href="#">KeePass 4 Web</a>
                </div>

                <div className="collapse navbar-collapse"  id="navbar-collapse-1">
                    {search}
                    <ul className="nav navbar-nav navbar-right">
                        <li className="dropdown">
                            <a href="#" className="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">{ cn }
                                <span className="caret"></span>
                            </a>
                            {dropdown}
                        </li>
                    </ul>
                </div>
            </nav>
        )
    }
};


