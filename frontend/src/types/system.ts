import type { PageQuery } from '@/types/api'

export interface CurrentUser {
  id: number
  username: string
  displayName: string
  departmentId: number
  departmentName: string
  roleCodes: string[]
  permissionCodes: string[]
}

export interface RoleSimple {
  id: number
  roleCode: string
  roleName: string
  riskLevel: 'NORMAL' | 'HIGH'
  status: 'ACTIVE' | 'DISABLED'
}

export interface User {
  id: number
  username: string
  displayName: string
  departmentId: number
  departmentName: string
  mobile?: string
  email?: string
  status: 'ACTIVE' | 'DISABLED' | 'LOCKED'
  lastLoginAt?: string
  createdAt: string
  updatedAt: string
  roles: RoleSimple[]
}

export interface UserPageQuery extends PageQuery {
  username?: string
  displayName?: string
  status?: string
  departmentId?: number
}

export interface UserCreatePayload {
  username: string
  displayName: string
  initialPassword: string
  departmentId: number
  mobile?: string
  email?: string
}

export interface UserUpdatePayload {
  displayName: string
  departmentId: number
  mobile?: string
  email?: string
  changeReason: string
}

export interface Role {
  id: number
  roleCode: string
  roleName: string
  riskLevel: 'NORMAL' | 'HIGH'
  description?: string
  status: 'ACTIVE' | 'DISABLED'
  isBuiltin: number
  createdAt: string
  updatedAt: string
  permissions: PermissionNode[]
}

export interface RolePageQuery extends PageQuery {
  keyword?: string
  status?: string
}

export interface RoleCreatePayload {
  roleCode: string
  roleName: string
  riskLevel: 'NORMAL' | 'HIGH'
  description?: string
}

export interface RoleUpdatePayload {
  roleName: string
  riskLevel: 'NORMAL' | 'HIGH'
  status: 'ACTIVE' | 'DISABLED'
  description?: string
  changeReason: string
}

export type PermissionType = 'MENU' | 'PAGE' | 'BUTTON' | 'DATA' | 'ACTION'

export interface PermissionNode {
  id: number
  parentId?: number
  permissionCode: string
  permissionName: string
  permissionType: PermissionType
  moduleCode: string
  resourceKey?: string
  routePath?: string
  httpMethod?: string
  apiPattern?: string
  status: 'ACTIVE' | 'DISABLED'
  sortOrder: number
  description?: string
  children: PermissionNode[]
}

export interface PermissionCreatePayload {
  parentId?: number
  permissionCode: string
  permissionName: string
  permissionType: PermissionType
  moduleCode: string
  resourceKey?: string
  routePath?: string
  httpMethod?: string
  apiPattern?: string
  sortOrder: number
  description?: string
}

export interface PermissionUpdatePayload {
  parentId?: number
  permissionName: string
  permissionType: PermissionType
  moduleCode: string
  resourceKey?: string
  routePath?: string
  httpMethod?: string
  apiPattern?: string
  status: 'ACTIVE' | 'DISABLED'
  sortOrder: number
  description?: string
  changeReason: string
}
