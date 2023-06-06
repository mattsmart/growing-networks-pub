import matplotlib.pyplot as plt
import numpy as np
import os

from class_singlecell import SingleCell
from dynamics_generic import simulate_dynamics_general
from dynamics_vectorfields import set_ode_vectorfield, ode_integration_defaults
from preset_solver import PRESET_SOLVER
from settings import STYLE_DYNAMICS, DIR_OUTPUT, PLOT_XLABEL, PLOT_YLABEL


def nan_mask(x, fill=1000):
    x_mask_arr = np.isfinite(x)
    x[~x_mask_arr] = fill
    return x


def XY_meshgrid(xlims, ylims, delta):
    x_a, x_b = xlims
    y_a, y_b = ylims
    x = np.arange(x_a, x_b, delta)
    y = np.arange(y_a, y_b, delta)
    X, Y = np.meshgrid(x, y)
    return X, Y


def example_vectorfield():
    ax_lims = 10
    Y, X = np.mgrid[-ax_lims:ax_lims:100j, -ax_lims:ax_lims:100j]
    U = -10 - X**2 + Y
    V = 10 + X - Y**2

    speed = np.sqrt(U**2 + V**2)
    lw = 5*speed / speed.max()

    fig = plt.figure(figsize=(7, 9))

    #  Varying density along a streamline
    plt.axhline(0, linestyle='--', color='k')
    plt.axvline(0, linestyle='--', color='k')

    ax0 = fig.gca()
    strm = ax0.streamplot(X, Y, U, V, density=[0.5, 1], color=speed, linewidth=lw)
    fig.colorbar(strm.lines)
    ax0.set_title('Varying Density, Color, Linewidth')
    ax0.set_xlabel('U')
    ax0.set_ylabel('V')

    plt.tight_layout()
    plt.show()
    return


def phaseplot_general(sc_template, ode_kwargs, init_conds=None, dynamics_method=STYLE_DYNAMICS, axlow=0., axhigh=120., ax=None,
                      **solver_kwargs):
    """
    ode_kwargs:
        'z': Scalar z represents static Bam concentration
        't': Scalar t represents time
    """
    # integration parameters
    t0, t1, num_steps, _ = ode_integration_defaults(sc_template.style_ode)
    times = np.linspace(t0, t1, num_steps + 1)

    if ax is None:
        plt.figure(figsize=(5, 5))
        ax = plt.gca()
    kw_endpoint_markers = {
        'marker': 'o',
        'markersize': 2,
        'markeredgecolor': 'k',
        'markeredgewidth': 0.2,
        'alpha': 1.0
    }

    if init_conds is None:
        nn = 10
        # random init conds
        """
        np.random.seed(0)
        init_conds = np.random.uniform(low=axlow, high=axhigh, size=(nn, sc_template.dim_ode))
        """
        # just above diagonal init conds - test physical boundary of the state space y > x > 0
        init_conds = np.zeros((2 * nn, sc_template.dim_ode))
        yy = np.linspace(axlow, axhigh, nn)
        init_conds[:nn, 0] = yy
        init_conds[:nn, 1] = yy
        # x = 0 boundary
        init_conds[nn:, 0] = 0
        init_conds[nn:, 1] = yy
        # fill third column with z if needed
        if sc_template.dim_ode > 2:
            init_conds[:, 2] = ode_kwargs.get('z', 0)
            print(sc_template.params_ode)
            print(init_conds[:, 2])

    for init_cond in init_conds:
        single_cell = SingleCell(
            init_cond_ode=init_cond,
            style_ode=sc_template.style_ode,
            params_ode=sc_template.params_ode, label='')
        print('phaseplot_general(): next init cond...')
        r, times = simulate_dynamics_general(init_cond, times, single_cell, dynamics_method=dynamics_method, **solver_kwargs)
        print('done traj')
        ax.plot(r[:, 0], r[:, 1], '-.', linewidth=0.5)
        # draw arrows every k points
        """
        # Note: see mpl quiver to do this vectorized
        k = 10
        for idx in range(0, num_steps, k):
            arrow_vec = r[idx+1, :] - r[idx,:]
            dx, dy, _ = arrow_vec
            x, y, _ = r[idx, :]
            print(x, y, dx, dy)
            ax.arrow(x, y, dx, dy, zorder=10, width=1e-4)"""
        # draw start (filled circle) and end point (open circle)
        ax.plot(r[0, 0], r[0, 1], markerfacecolor='k', **kw_endpoint_markers)
        ax.plot(r[-1, 0], r[-1, 1], markerfacecolor='none', **kw_endpoint_markers)

    # decorators
    ax.axhline(0, linestyle='--', color='k')
    ax.axvline(0, linestyle='--', color='k')
    diagline = np.linspace(0, axhigh, 100)
    ax.plot(diagline, diagline, linestyle='--', color='gray')

    ax.set_xlabel(PLOT_XLABEL)
    ax.set_ylabel(PLOT_YLABEL)
    ax.set_title('Example trajectories')
    plt.savefig(DIR_OUTPUT + os.sep + 'phaseplot_%s.pdf' % sc_template.style_ode)
    plt.show()
    return ax


def vectorfield_general(sc_template, ode_kwargs, delta=0.1, axlow=0.0, axhigh=120.0):
    """
    ode_kwargs:
        'z': Scalar z represents static Bam concentration
        't': Scalar t represents time
    """
    params = sc_template.params_ode
    X, Y = XY_meshgrid([axlow, axhigh], [axlow, axhigh], delta)

    if sc_template.dim_ode == 3:
        z = ode_kwargs.get('z', 0)
        init_cond_mesh = (X, Y, z * np.ones_like(X))
        dxdt = set_ode_vectorfield(sc_template.style_ode, params, init_cond_mesh, **ode_kwargs)
        U, V, _ = dxdt
    else:
        assert sc_template.dim_ode == 2
        init_cond_mesh = (X, Y)
        dxdt = set_ode_vectorfield(sc_template.style_ode, params, init_cond_mesh, **ode_kwargs)
        U, V = dxdt

    U = nan_mask(U)
    V = nan_mask(V)

    # Block for example code
    speed = np.sqrt(U**2 + V**2)
    lw = 5 * speed / speed.max()

    fig = plt.figure(figsize=(5, 5))
    ax0 = fig.gca()
    # decorators
    ax0.axhline(0, linewidth=1, linestyle='--', color='k')
    ax0.axvline(0, linewidth=1, linestyle='--', color='k')
    diagline = np.linspace(0, axhigh, 100)
    ax0.plot(diagline, diagline, linewidth=1, linestyle='--', color='gray')

    strm = ax0.streamplot(X, Y, U, V, density=[0.5, 1], color=speed, linewidth=lw)
    fig.colorbar(strm.lines)
    ax0.set_title('%s Vector field' % sc_template.style_ode)
    ax0.set_xlabel(PLOT_XLABEL)
    ax0.set_ylabel(PLOT_YLABEL)

    plt.tight_layout()
    plt.show()


def contourplot_general(sc_template, ode_kwargs, delta=0.1, axlow=0.0, axhigh=120.0):
    """
    ode_kwargs:
        'z': Scalar z represents static Bam concentration
        't': Scalar t represents time
    """
    X, Y = XY_meshgrid([axlow, axhigh], [axlow, axhigh], delta)

    params = sc_template.params_ode
    dxdt = set_ode_vectorfield(sc_template.style_ode, params, (X, Y), **ode_kwargs)
    U, V = dxdt
    U = nan_mask(U)
    V = nan_mask(V)

    fig, ax = plt.subplots(1, 3)
    contours_u = ax[0].contour(X, Y, U)
    ax[0].clabel(contours_u, inline=1, fontsize=10)
    ax[0].set_title('U contours')
    ax[0].set_xlabel('U')
    ax[0].set_ylabel('V')

    contours_v = ax[1].contour(X, Y, V)
    ax[1].clabel(contours_v, inline=1, fontsize=10)
    ax[1].set_title('V contours')
    ax[1].set_xlabel('U')
    ax[1].set_ylabel('V')

    ax[2].set_title('U, V contours overlaid')
    ax[2].set_xlabel('U')
    ax[2].set_ylabel('V')

    plt.show()


def nullclines_general(sc_template, ode_kwargs, flip_axis=False, contour_labels=True,
                       delta=0.1, axlow=0.0, axhigh=120.0, ax=None):
    """
    ode_kwargs
        't': optional parameter for PWL
        'z': optional parameter for Yang2013
    """
    X, Y = XY_meshgrid([axlow, axhigh], [axlow, axhigh], delta)
    init_cond = [X, Y]
    if sc_template.dim_ode > 2:
        for idx in range(2, sc_template.dim_ode):
            print('...')
            if idx == 2:
                z = ode_kwargs.get('z', 0)
                Z = z * np.ones_like(X)
                init_cond.append(Z)
            else:
                assert idx == 3
                w = ode_kwargs.get('w', 0)
                W = w * np.ones_like(X)
                init_cond.append(W)

    params = sc_template.params_ode
    dXdt = set_ode_vectorfield(sc_template.style_ode, params, init_cond, **ode_kwargs)
    U = dXdt[0]
    V = dXdt[1]

    U = nan_mask(U)
    V = nan_mask(V)

    if flip_axis:
        # swap X, Y
        tmp = X
        X = Y
        Y = tmp
        # swap labels
        label_x = PLOT_YLABEL
        label_y = PLOT_XLABEL
    else:
        label_x = PLOT_XLABEL
        label_y = PLOT_YLABEL

    if ax is None:
        plt.figure(figsize=(5, 5))
        ax = plt.gca()

    # plot nullclines
    nullcline_u = ax.contour(X, Y, U, (0,), colors='b', linewidths=1.5)
    nullcline_v = ax.contour(X, Y, V, (0,), colors='r', linewidths=1.5)
    if contour_labels:
        ax.clabel(nullcline_u, inline=1, fmt='X nc', fontsize=10)
        ax.clabel(nullcline_v, inline=1, fmt='Y nc', fontsize=10)
    # decorators
    ax.axhline(0, linewidth=1, linestyle='--', color='k')
    ax.axvline(0, linewidth=1, linestyle='--', color='k')
    diagline = np.linspace(0, axhigh, 100)
    ax.plot(diagline, diagline, linewidth=1, linestyle='--', color='gray')
    # plot labels
    ax.set_title('%s nullclines (blue=%s, red=%s)' % (sc_template.style_ode, PLOT_XLABEL, PLOT_YLABEL))
    ax.set_xlabel(label_x)
    ax.set_ylabel(label_y)
    plt.show()
    return ax


if __name__ == '__main__':

    """['Yang2013', 'bpj2017', 'PWL3_bpj2017', 'PWL2', 'PWL3', 'PWL3_swap', 
        'PWL4_auto_wz', 'PWL4_auto_ww', 'PWL4_auto_linear',
        'toy_flow', 'toy_clock']"""
    style_ode = 'PWL3_swap'  # main ones are: PWL3_swap, PWL3_bpj2017, bpj2017, Yang2013

    flag_phaseplot = False
    flag_vectorfield = True
    flag_contourplot = False
    flag_nullclines = True

    solver_kwargs = PRESET_SOLVER['solve_ivp_radau_default']['kwargs']
    sc_template = SingleCell(style_ode=style_ode)

    if style_ode == 'Yang2013':
        sc_kwargs = {
            'z': 0
        }
        axlow = 0
        axhigh = 120
    elif style_ode == 'PWL2':
        sc_kwargs = {
            't': 0
        }
        axlow = 0
        axhigh = 12
    elif style_ode == 'PWL4_auto_linear':
        sc_kwargs = {
            't': 0,  # this should have no affect on the autonomous equations
            'z': 1.5,  # note z represents the x-intercept of the dydt=0 nullcline
            'w': 0  # currently this has no affect
        }
        axlow = 0
        axhigh = 5
    elif style_ode == 'PWL3_swap':
        z = 2.8
        sc_kwargs = {
            't': 0,  # this should have no affect on the autonomous equations, since we set pulse vel to zero
            'z': z,  # note z represents the x-intercept of the dydt=0 nullcline
        }
        sc_template.params_ode['pulse_vel'] = 0  # need to make it so "z" doesn't change (want static picture here)
        axlow = 0
        axhigh = 10
    elif style_ode == 'bpj2017':
        sc_kwargs = {
            'z': 1.5,  # currently no effect
        }
        axlow = 0
        axhigh = 2
    elif style_ode == 'PWL3_bpj2017':
        z = 2.8
        sc_kwargs = {
            't': 0,  # this should have no affect on the autonomous equations, since we set pulse vel to zero
            'z': z,  # currently no effect
        }
        sc_template.params_ode['pulse_vel'] = 0  # need to make it so "z" doesn't change (want static picture here)
        axlow = 0
        axhigh = 10
    else:
        sc_template = None
        axlow, axhigh = None, None
        sc_kwargs = None

    delta = (axhigh - axlow) * 1e-3
    if flag_phaseplot:
        phaseplot_general(sc_template, sc_kwargs, axlow=axlow, axhigh=axhigh, **solver_kwargs)
    if flag_vectorfield:
        vectorfield_general(sc_template, sc_kwargs, delta=delta, axlow=axlow, axhigh=axhigh)
    if flag_contourplot:
        contourplot_general(sc_template, sc_kwargs, delta=delta, axlow=axlow, axhigh=axhigh)
    if flag_nullclines:
        nullclines_general(sc_template, sc_kwargs, delta=delta, axlow=axlow, axhigh=axhigh, contour_labels=False)
