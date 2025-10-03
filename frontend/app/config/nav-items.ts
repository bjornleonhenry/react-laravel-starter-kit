import { CirclePlay, LayoutGrid, SquareCode, Tractor, User } from 'lucide-react'
import type { NavItem } from '~/core/types'

export const mainNavItems: NavItem[] = [
    {
        title: 'Dashboard',
        to: '/dashboard',
        icon: LayoutGrid,
    },
    {
        title: 'Users',
        to: '/users',
        icon: User,
    },
]

export const footerNavItems: NavItem[] = [
    {
        title: 'React Frontend',
        to: 'https://github.com/bjornleonhenry/react-laravel-frontend',
        icon: CirclePlay,
    },
    {
        title: 'Laravel Backend',
        to: 'https://github.com/bjornleonhenry/react-laravel-backend',
        icon: SquareCode,
    },
    {
        title: 'React Laravel Kit',
        to: 'https://github.com/bjornleonhenry/react-laravel-starter-kit',
        icon: Tractor,
    },
]