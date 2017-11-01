import React from 'react'
import Timer from './Timer'
window.$ = window.jQuery = require('jquery')
var Bootstrap = require('bootstrap')


export default class NavBar extends React.Component {
    constructor() {
        super()
        this.onLogout = this.onLogout.bind(this)
        this.onCloseDB = this.onCloseDB.bind(this)
        this.onTimeUp  = this.onTimeUp.bind(this)
    }

    onLogout() {
        this.serverRequest = KeePass4Web.ajax('logout', {
            success: function () {
                KeePass4Web.clearStorage()
                this.props.router.replace('/user_login')
            }.bind(this),
            error: KeePass4Web.error.bind(this),
        })
    }

    onCloseDB(event, state) {
        this.serverRequest = KeePass4Web.ajax('close_db', {
            success: function () {
                // redirect to home, so checks for proper login can be made

                var router = this.props.router
                // we haven't changed page, so need a workaround
                router.replace('/db_login')
                router.replace({
                    state: state,
                    pathname: '/'
                })
            }.bind(this),
            error: KeePass4Web.error.bind(this),
        })
    }

    onTimeUp() {
        this.onCloseDB(null, {
            info: 'Database session expired'
        })
    }

    componentDidMount() {
        if (KeePass4Web.getSettings().cn) {
            document.getElementById('logout').addEventListener('click', this.onLogout)
            document.getElementById('closeDB').addEventListener('click', this.onCloseDB)
        }
    }

    componentWillUnmount() {
        if (this.serverRequest)
            this.serverRequest.abort()
    }

    render() {
        var cn = KeePass4Web.getSettings().cn
        var dropdown, search, timer
        if (cn) {
            dropdown = (
                <ul className="dropdown-menu">
                    <li><a id="logout">Logout</a></li>
                    <li role="separator" className="divider"></li>
                    <li><a id="closeDB">Close Database</a></li>
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
                    <div className="navbar-text">
                        <Timer
                            format='{hh}:{mm}:{ss}'
                            timeout={timeout}
                            onTimeUp={this.onTimeUp}
                            restart={KeePass4Web.restartTimer}
                        />
                        <label type="button" className="btn btn-secondary btn-xs" onClick={KeePass4Web.restartTimer.bind(this, true)}>
                            <span className="glyphicon glyphicon-repeat"></span>
                        </label>
                    </div>
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
                    {timer}
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

