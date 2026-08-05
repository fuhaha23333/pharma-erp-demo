package com.fuhaha.pharmaerp;

import com.fuhaha.pharmaerp.modules.trace.service.BatchTraceService;
import com.fuhaha.pharmaerp.security.DatabaseUserDetailsService;
import com.fuhaha.pharmaerp.security.PermissionCodes;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class PharmaErpApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private BatchTraceService batchTraceService;

    @MockBean
    private DatabaseUserDetailsService userDetailsService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Test
    void contextLoads() {
    }

    @Test
    void openApiKeepsAllPhaseOneModules() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.info.version").value("phase-1"))
                .andExpect(jsonPath("$.paths['/system/users'].post").exists())
                .andExpect(jsonPath("$.paths['/system/roles'].post").exists())
                .andExpect(jsonPath("$.paths['/system/permissions/tree'].get").exists())
                .andExpect(jsonPath("$.paths['/quality/suppliers/{supplierId}/submit'].post").exists())
                .andExpect(jsonPath("$.paths['/trace/batches/{batchNo}'].get").exists());
    }

    @Test
    void businessApiRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/trace/batches/LOT-001"))
                .andExpect(status().isUnauthorized())
                .andExpect(header().doesNotExist(HttpHeaders.WWW_AUTHENTICATE))
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void invalidBasicCredentialsReturnJsonWithoutBrowserChallenge() throws Exception {
        when(userDetailsService.loadUserByUsername("admin")).thenReturn(User.withUsername("admin")
                .password(passwordEncoder.encode("correct-password"))
                .authorities(PermissionCodes.TRACE_READ)
                .build());

        mockMvc.perform(get("/trace/batches/LOT-001")
                        .with(httpBasic("admin", "wrong-password")))
                .andExpect(status().isUnauthorized())
                .andExpect(header().doesNotExist(HttpHeaders.WWW_AUTHENTICATE))
                .andExpect(jsonPath("$.code").value(401))
                .andExpect(jsonPath("$.message").value("认证失败，请提供有效账号和密码"));
    }

    @Test
    @WithMockUser
    void traceApiRejectsUserWithoutAuthority() throws Exception {
        mockMvc.perform(get("/trace/batches/LOT-001"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(403));
    }

    @Test
    @WithMockUser(authorities = PermissionCodes.TRACE_READ)
    void traceApiAllowsAuthorizedUser() throws Exception {
        when(batchTraceService.traceByBatchNo("LOT-001", null)).thenReturn(List.of());

        mockMvc.perform(get("/trace/batches/LOT-001"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
    }

    @Test
    @WithMockUser(authorities = PermissionCodes.SYS_USER_READ)
    void malformedPathVariableReturnsBadRequestInsteadOfServerError() throws Exception {
        mockMvc.perform(get("/system/users/not-a-number"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }
}
