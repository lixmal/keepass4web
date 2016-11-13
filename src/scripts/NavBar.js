import React from 'react'
import Timer from './Timer'
window.$ = window.jQuery = require('jquery')
var Bootstrap = require('bootstrap')


export default class NavBar extends React.Component {
    constructor() {
        super()
        this.onLogout  = this.onLogout.bind(this)
        this.onCloseDB = this.onCloseDB.bind(this)
        this.onTimeUp  = this.onTimeUp.bind(this)
    }

    onLogout() {
        KeePass4Web.logout(this.props.router)
    }

    onCloseDB () {
        KeePass4Web.closeDB(this.props.router)
    }

    onTimeUp() {
        this.onCloseDB()
        alert('Database session expired')
    }

    componentDidMount() {
        if (KeePass4Web.getSettings().cn) {
            document.getElementById('logout').addEventListener('click', this.onLogout)
            document.getElementById('closeDB').addEventListener('click', this.onCloseDB)
        }
    }

    render() {
        var cn = KeePass4Web.getSettings().cn
        var dropdown, search, timer
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
                <form className="navbar-form navbar-left" role="search" onSubmit={this.props.onSearch.bind(this, this.refs)}>
                    <div className="input-group">
                        <input autoComplete="on" type="search" ref="term" className="form-control" placeholder="Search" autoFocus />
                        <div className="input-group-btn">
                            <button type="submit" className="btn btn-default"><span className="glyphicon glyphicon-search"></span></button>
                        </div>
                    </div>
                </form>
            )
            let timeout = KeePass4Web.getSettings().timeout
            if (timeout) {
                timer = (
                    <Timer
                        format='{hh}:{mm}:{ss}'
                        timeout={timeout}
                        onTimeUp={this.onTimeUp}
                        restart={KeePass4Web.restartTimer}
                    />
                )
            }
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
                    <div className="navbar-text">{timer}</div>
                </div>
                <div className="collapse navbar-collapse" id="navbar-collapse-1">
                    {search}
                    <ul className="nav navbar-nav navbar-right">
                        <li className="dropdown">
                            <a href="#" className="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false">
                                {cn}
                                <span className="caret"></span>
                            </a>
                            {dropdown}
                        </li>
                    </ul>
                </div>
            </nav>
        )
    }
}


