import { request } from '@/api/http'
import type { PageResult } from '@/types/api'
import type {
  PermissionCreatePayload,
  PermissionNode,
  PermissionUpdatePayload,
  Role,
  RoleCreatePayload,
  RolePageQuery,
  RoleUpdatePayload,
  User,
  UserCreatePayload,
  UserPageQuery,
  UserUpdatePayload,
} from '@/types/system'
import { compactParams } from '@/utils/format'

export function getUsers(params: UserPageQuery): Promise<PageResult<User>> {
  return request<PageResult<User>>({
    method: 'GET',
    url: '/system/users/page',
    params: compactParams(params),
  })
}

export function getUser(userId: number): Promise<User> {
  return request<User>({ method: 'GET', url: `/system/users/${userId}` })
}

export function createUser(payload: UserCreatePayload): Promise<User> {
  return request<User>({ method: 'POST', url: '/system/users', data: payload })
}

export function updateUser(userId: number, payload: UserUpdatePayload): Promise<User> {
  return request<User>({ method: 'PUT', url: `/system/users/${userId}`, data: payload })
}

export async function changeUserStatus(
  userId: number,
  status: 'ACTIVE' | 'DISABLED',
  reason: string,
): Promise<void> {
  await request<null>({
    method: 'PUT',
    url: `/system/users/${userId}/status`,
    data: { status, reason },
  })
}

export async function assignUserRoles(
  userId: number,
  roleIds: number[],
  reason: string,
): Promise<void> {
  await request<null>({
    method: 'PUT',
    url: `/system/users/${userId}/roles`,
    data: { roleIds, reason },
  })
}

export function getRoles(params: RolePageQuery): Promise<PageResult<Role>> {
  return request<PageResult<Role>>({
    method: 'GET',
    url: '/system/roles/page',
    params: compactParams(params),
  })
}

export function getRole(roleId: number): Promise<Role> {
  return request<Role>({ method: 'GET', url: `/system/roles/${roleId}` })
}

export function createRole(payload: RoleCreatePayload): Promise<Role> {
  return request<Role>({ method: 'POST', url: '/system/roles', data: payload })
}

export function updateRole(roleId: number, payload: RoleUpdatePayload): Promise<Role> {
  return request<Role>({ method: 'PUT', url: `/system/roles/${roleId}`, data: payload })
}

export async function assignRolePermissions(
  roleId: number,
  permissionIds: number[],
  reason: string,
): Promise<void> {
  await request<null>({
    method: 'PUT',
    url: `/system/roles/${roleId}/permissions`,
    data: { permissionIds, reason },
  })
}

export function getPermissionTree(includeDisabled = false): Promise<PermissionNode[]> {
  return request<PermissionNode[]>({
    method: 'GET',
    url: '/system/permissions/tree',
    params: { includeDisabled },
  })
}

export function createPermission(payload: PermissionCreatePayload): Promise<PermissionNode> {
  return request<PermissionNode>({
    method: 'POST',
    url: '/system/permissions',
    data: payload,
  })
}

export function updatePermission(
  permissionId: number,
  payload: PermissionUpdatePayload,
): Promise<PermissionNode> {
  return request<PermissionNode>({
    method: 'PUT',
    url: `/system/permissions/${permissionId}`,
    data: payload,
  })
}
