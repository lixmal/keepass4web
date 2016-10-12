import jQuery from 'jquery'
import Css from '../style/app.css';
import React from 'react'
import ReactDOM from 'react-dom'
import { withRouter, useRouterHistory, Router, Route } from 'react-router'
import { createHashHistory } from 'history'

import Viewport from './Viewport'

import UserLogin from './UserLogin'
import BackendLogin from './BackendLogin'
import DBLogin from './DBLogin'

const View        = withRouter(Viewport)
const UserForm    = withRouter(UserLogin)
const BackendForm = withRouter(BackendLogin)
const DBForm      = withRouter(DBLogin)

const appHistory = useRouterHistory(createHashHistory)({ queryKey: false })

// global namespace
window.KeePass4Web = {}

KeePass4Web.checkAuth = function(nextState, replace) {
    var auth

    KeePass4Web.ajax('authenticated', {
        error: function(r, s, e) {
            if (r.status == 401 && r.responseJSON)
                auth = r.responseJSON.message
            else
                KeePass4Web.error(r, s, e)
        }.bind(this),
        async: false
    })


    if (!auth) return

    if (auth.data) {
        KeePass4Web.setCN(auth.data.cn)
        KeePass4Web.setTemplate(auth.data.credentials_tpl)
    }

    // route to proper login page if unauthenticated
    // in that order
    var origPath = nextState.location.pathname
    if (!auth.user && origPath !== '/user_login' ) {
        KeePass4Web.clearStorage()
        replace({
            pathname: 'user_login',
            state: { nextPathname: origPath }
        })
    }
    else if (!auth.backend && origPath !== '/backend_login' ) {
        let type = auth.data.credentials_tpl.type
        if (type === 'redirect') {
            window.location = auth.data.credentials_tpl.url
            // stopping javascript execution to prevent redirect loop
            throw 'Redirecting'
        }
        else if (type === 'mask')
            replace({
                pathname: 'backend_login',
                state: { nextPathname: origPath }
            })
    }
    else if (!auth.db && origPath !== '/db_login' ) {
        replace({
            pathname: 'db_login',
            state: { nextPathname: origPath }
        })
    }

    /*
    // route to root if user tries to open login page for some reason
    else if (success && origPath === '/login' ) {
        replace({
            pathname: '/',
            state: { nextPathname: origPath }
        })
    }
    */
}

// simple wrapper for ajax calls, in case implementation changes
KeePass4Web.ajax = function(url, conf) {
    conf.url  = url

    // set defaults
    conf.method   = typeof conf.method   === 'undefined' ? 'POST' : conf.method
    conf.dataType = typeof conf.dataType === 'undefined' ? 'json' : conf.dataType

    /*
    if (conf.error === undefined) {
        conf.error = function(r, s, e) {
            // reload page if auth expired
            if (r.status == 401)
                location.reload(true)

            // call passed callback
            conf.error(r, s, e)
        }.bind(this)
    }
    */

    jQuery.ajax(conf)
}

KeePass4Web.logout = function(router) {
    KeePass4Web.clearStorage()
    KeePass4Web.ajax('logout', {
        // need async, else check for authenticated may finish first
        async: false,
        complete: function() {
            router.replace('/user_login')
        }
    })
}

KeePass4Web.closeDB = function(router) {
    KeePass4Web.ajax('close_db', {
        complete: function() {
            // redirect to home, so checks for proper login can be made

            // we haven't changed page, so need a workaround
            router.replace('/db_login')
            router.replace('/')
        },
    })
}

// leave room for implementation changes
KeePass4Web.setCN = function(cn) {
    localStorage.setItem('cn', cn || '')
}

KeePass4Web.getCN = function() {
    return localStorage.getItem('cn') || null
}

KeePass4Web.clearStorage = function() {
    localStorage.removeItem('cn')
    localStorage.removeItem('template')
}

KeePass4Web.setTemplate = function(template) {
    localStorage.setItem('template', JSON.stringify(template))
}

KeePass4Web.getTemplate = function() {
    return JSON.parse(localStorage.getItem('template'))
}

KeePass4Web.error = function(r, s, e) {
    if (r.status == 401) {
        if (this.props && this.props.router) {
            // redirect first, to hide sensitive data
            this.props.router.replace('/db_login')
            this.props.router.replace('/')
            alert('Your session expired')
        }
        else {
            alert('Your session expired')
            location.reload()
        }
    }
    else {
        let error = e
        if (r.responseJSON)
            error = r.responseJSON.message
        alert(e)
    }
}


ReactDOM.render(
    <Router history={appHistory}>
        <Route path='/'              component={View} onEnter={KeePass4Web.checkAuth} />
        <Route path='/user_login'    component={UserForm} />
        <Route path='/backend_login' component={BackendForm} />
        <Route path='/db_login'      component={DBForm} />
    </Router>,
    document.getElementById('app-content')
);
