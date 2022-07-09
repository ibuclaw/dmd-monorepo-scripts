#!/bin/bash
set -e
workdir=workdir

###############################################################################
if [ "$1" = "subtree" ];
then
    ##
    # Setup work directory (yes we are cloning everything).
    for repo in dmd druntime phobos tools installer dlang.org; do
	git clone https://github.com/dlang/$repo $workdir/$repo
    done

    ##
    # This is the last revision before we merged dmd and druntime!
    git -C $workdir/dmd tag -sm last-separate-dmd-druntime last-separate-dmd-druntime

    ##
    # Move dmd files into subdirectory before any $workdir merging. 
    mkdir $workdir/dmd/compiler
    git -C $workdir/dmd mv {changelog,docs,ini,samples,src,test} compiler/
    patch -d $workdir/dmd -p1 -i ../../patches/move_compiler/0001-Fix-pre-commit-config-post-moving-compiler.patch
    git -C $workdir/dmd add .pre-commit-config.yaml
    git -C $workdir/dmd commit -m 'Move dmd files into compiler/'

    ##
    # Do the merge
    git -C $workdir/dmd remote add -f --no-tags druntime https://github.com/dlang/druntime
    git -C $workdir/dmd merge -s ours --no-commit --allow-unrelated-histories druntime/master
    git -C $workdir/dmd read-tree --prefix=druntime/ -u druntime/master
    git -C $workdir/dmd commit -m "Merge dlang/druntime repository into dlang/dmd"

    ##
    # ??? Is this necessary? doesn't seem to be.
    #git -C $workdir/dmd pull -s subtree druntime master

    ##
    # Post-merge fix-ups
    git -C $workdir/dmd checkout master
    git -C $workdir/dmd am ../../patches/master/0001-Fix-build-script-paths-to-work-with-new-merged-repos.patch
    git -C $workdir/dmd am ../../patches/master/0001-src-posix.mak-Add-proxy.patch
    git -C $workdir/dmd am ../../patches/master/0002-src-posix.mak-Use-QUIET.patch
    git -C $workdir/dmd am ../../patches/master/0003-src-README-Initial-commit.patch
    git -C $workdir/dmd am ../../patches/master/0004-src-osmodel.mak-Add-redirect.patch
    git -C $workdir/dmd am ../../patches/master/0005-dub.sdl-Update-paths.patch
    git -C $workdir/dmd am ../../patches/master/0006-dub.sdl-Add-explicit-importPaths.patch

    git -C $workdir/phobos am ../../patches/phobos/0001-Fix-build-script-paths-to-work-with-new-merged-dmd-d.patch

    git -C $workdir/dlang.org am ../../patches/dlang.org/0001-posix.mak-Update-src-paths-for-DMD-Druntime-monorepo.patch
    git -C $workdir/dlang.org am ../../patches/dlang.org/0002-posix.mak-Update-docs-paths-for-DMD-Druntime-monorep.patch
    git -C $workdir/dlang.org am ../../patches/dlang.org/0003-posix.mak-Disable-parallel-GC-in-DPL_DOCS.patch

    git -C $workdir/dlang.org am ../../patches/ci/0001-Fix-build-script-paths-to-work-with-new-merged-repos.patch

    ##
    # This is the first revision with a working merged structure!
    git -C $workdir/dmd tag -sm first-merged-dmd-druntime first-merged-dmd-druntime
    git -C $workdir/dmd remote remove druntime
    git -C $workdir/dmd gc

###############################################################################
elif [ "$1" = "build" ];
then
    ##
    # Build and test dmd
    make -C $workdir/dmd -f posix.mak -j$(nproc)
    make -C $workdir/phobos -f posix.mak -j$(nproc)
    make -C $workdir/dmd -f posix.mak test -j$(nproc)
    # ??? Merge druntime unittests with dmd test?
    make -C $workdir/dmd/druntime -f posix.mak unittest -j$(nproc)
    make -C $workdir/phobos -f posix.mak unittest -j$(nproc)

###############################################################################
elif [ "$1" = "druntime-tags" ];
then
    ##
    # ??? Carry over druntime tags into the dmd repository.
    # Generated with:
    #for committag in $(git -C $workdir/dmd ls-remote --tags druntime  | grep "{}$" | awk '{print $1"%"$2 }')
    #do
    #    commit="${committag%%%*}"
    #    tag="${committag#*%refs/tags/}"
    #    tag="${tag%%^{\}}"
    #    case "$tag" in
    #	druntime-*)
    #	    newtag=$tag
    #	    ;;
    #	dmd-*)
    #	    newtag=$druntime-{tag#*dmd-}
    #	    ;;
    #	*)
    #	    newtag=druntime-$tag
    #	    ;;
    #    esac
    #    echo git -C $workdir/dmd tag -sm $tag $newtag $commit
    #done
    git -C $workdir/dmd tag -sm druntime-2.052 druntime-2.052 bc731e9e66a4560ebb1a1a893f0abdaeb1fbee55
    git -C $workdir/dmd tag -sm v2.054 druntime-v2.054 fbffa21cacf8b2dab55f3fe6bf7e91e5f80c8006
    git -C $workdir/dmd tag -sm v2.055 druntime-v2.055 034823ac4429e015b5a0f2e284c96bfc68a2aaa9
    git -C $workdir/dmd tag -sm v2.056 druntime-v2.056 b7270004a95c33372e5b15bc72069c001b064acf
    git -C $workdir/dmd tag -sm v2.057 druntime-v2.057 71f5445b14177ea58ec2c10b6a8e096e37643890
    git -C $workdir/dmd tag -sm v2.058 druntime-v2.058 f28e0e53841070047abed9858bddd28fe870f6a7
    git -C $workdir/dmd tag -sm v2.059 druntime-v2.059 8b501dc1a67eccd8dced6846bdcc22660bb50c16
    git -C $workdir/dmd tag -sm v2.060 druntime-v2.060 7ff4fb1e37e00caa7187b39bda403377d888400d
    git -C $workdir/dmd tag -sm v2.064-beta3 druntime-v2.064beta3 c0978e9384c4d3cc99788eea84fbba2d4df329fe
    git -C $workdir/dmd tag -sm v2.065-b1 druntime-v2.065-b1 5b6458be8d181f78698f0b2a6b98598b2b8596ce
    git -C $workdir/dmd tag -sm v2.065.0 druntime-v2.065.0 5b6458be8d181f78698f0b2a6b98598b2b8596ce
    git -C $workdir/dmd tag -sm v2.065.0-b2 druntime-v2.065.0-b2 5b6458be8d181f78698f0b2a6b98598b2b8596ce
    git -C $workdir/dmd tag -sm v2.065.0-b3 druntime-v2.065.0-b3 5b6458be8d181f78698f0b2a6b98598b2b8596ce
    git -C $workdir/dmd tag -sm v2.065.0-rc1 druntime-v2.065.0-rc1 5b6458be8d181f78698f0b2a6b98598b2b8596ce
    git -C $workdir/dmd tag -sm v2.066.0 druntime-v2.066.0 1aabbb24e7813c101bdb1c17c4ee17d09eb093c8
    git -C $workdir/dmd tag -sm v2.066.0-b1 druntime-v2.066.0-b1 c661eeab776dd2353c799222bf36b89fa7148cba
    git -C $workdir/dmd tag -sm v2.066.0-b2 druntime-v2.066.0-b2 23e7eb3abd061d292c2672d89036f46d0e9c042d
    git -C $workdir/dmd tag -sm v2.066.0-b3 druntime-v2.066.0-b3 d8fc4a0961886c2368f6d6436c4c87347a14bdb6
    git -C $workdir/dmd tag -sm v2.066.0-b4 druntime-v2.066.0-b4 e36d35c39ebebe4d9567053bb755656ec0551dd5
    git -C $workdir/dmd tag -sm v2.066.0-b5 druntime-v2.066.0-b5 5dbccd493f3ba3a2ad4665c168cb0a7c49d58545
    git -C $workdir/dmd tag -sm v2.066.0-b6 druntime-v2.066.0-b6 1aabbb24e7813c101bdb1c17c4ee17d09eb093c8
    git -C $workdir/dmd tag -sm v2.066.0-rc1 druntime-v2.066.0-rc1 1aabbb24e7813c101bdb1c17c4ee17d09eb093c8
    git -C $workdir/dmd tag -sm v2.066.0-rc2 druntime-v2.066.0-rc2 1aabbb24e7813c101bdb1c17c4ee17d09eb093c8
    git -C $workdir/dmd tag -sm v2.067.0 druntime-v2.067.0 ce12e759f62451aa2967eb1962f210f203f790ad
    git -C $workdir/dmd tag -sm v2.067.0-b1 druntime-v2.067.0-b1 52617d5cdefba5377efea9fc1d094dc68e11ebd6
    git -C $workdir/dmd tag -sm v2.067.0-rc1 druntime-v2.067.0-rc1 ce12e759f62451aa2967eb1962f210f203f790ad
    git -C $workdir/dmd tag -sm v2.067.1 druntime-v2.067.1 eeb01a68b992af0e87cbcf884a5aaf7a2035d2d6
    git -C $workdir/dmd tag -sm v2.067.1-b1 druntime-v2.067.1-b1 eeb01a68b992af0e87cbcf884a5aaf7a2035d2d6
    git -C $workdir/dmd tag -sm v2.068.0 druntime-v2.068.0 0ca25648947bb8f27d08dc618f23ab86fddea212
    git -C $workdir/dmd tag -sm v2.068.0-b1 druntime-v2.068.0-b1 02e1c440973eff3dbe7683db81d9316d668282d8
    git -C $workdir/dmd tag -sm v2.068.0-b2 druntime-v2.068.0-b2 ad900eb3cc38397c4fa3a0a805793f002d03abc7
    git -C $workdir/dmd tag -sm v2.068.0-rc1 druntime-v2.068.0-rc1 0ca25648947bb8f27d08dc618f23ab86fddea212
    git -C $workdir/dmd tag -sm v2.068.1 druntime-v2.068.1 ba9ea9ebaaed3c96024d74463926daf45479cfee
    git -C $workdir/dmd tag -sm v2.068.1-b1 druntime-v2.068.1-b1 281bf608c07b0acdfc5ff97e1699057896082155
    git -C $workdir/dmd tag -sm v2.068.1-b2 druntime-v2.068.1-b2 281bf608c07b0acdfc5ff97e1699057896082155
    git -C $workdir/dmd tag -sm v2.068.2 druntime-v2.068.2 a0daf0fc3b9e8c0cc14912e439ef82235f4a2bac
    git -C $workdir/dmd tag -sm v2.068.2-b1 druntime-v2.068.2-b1 a0daf0fc3b9e8c0cc14912e439ef82235f4a2bac
    git -C $workdir/dmd tag -sm v2.068.2-b2 druntime-v2.068.2-b2 a0daf0fc3b9e8c0cc14912e439ef82235f4a2bac
    git -C $workdir/dmd tag -sm v2.069.0 druntime-v2.069.0 82715d0589d815a77c7139a59193899866a35f02
    git -C $workdir/dmd tag -sm v2.069.0-b1 druntime-v2.069.0-b1 480dc88ed946fa074196ef870157a5f63f7f7b0b
    git -C $workdir/dmd tag -sm v2.069.0-b2 druntime-v2.069.0-b2 d3dad79e43a703800ae4407b3d33812f869e3fcc
    git -C $workdir/dmd tag -sm v2.069.0-rc1 druntime-v2.069.0-rc1 d3dad79e43a703800ae4407b3d33812f869e3fcc
    git -C $workdir/dmd tag -sm v2.069.0-rc2 druntime-v2.069.0-rc2 82715d0589d815a77c7139a59193899866a35f02
    git -C $workdir/dmd tag -sm v2.069.1 druntime-v2.069.1 82715d0589d815a77c7139a59193899866a35f02
    git -C $workdir/dmd tag -sm v2.069.2 druntime-v2.069.2 fdad9f502dc3a5cac0bac0cfa7d55fc4b7c273b5
    git -C $workdir/dmd tag -sm v2.069.2-b1 druntime-v2.069.2-b1 fdad9f502dc3a5cac0bac0cfa7d55fc4b7c273b5
    git -C $workdir/dmd tag -sm v2.069.2-b2 druntime-v2.069.2-b2 fdad9f502dc3a5cac0bac0cfa7d55fc4b7c273b5
    git -C $workdir/dmd tag -sm v2.070.0 druntime-v2.070.0 bf92678561b5ae662332cc5e104c39509fdfb130
    git -C $workdir/dmd tag -sm v2.070.0-b1 druntime-v2.070.0-b1 549752a4f435765095a99254fe61fa7cd9dd0d51
    git -C $workdir/dmd tag -sm v2.070.0-b2 druntime-v2.070.0-b2 b883d9791f2c08256edcdacf45a7f13cdda47ef2
    git -C $workdir/dmd tag -sm v2.070.1 druntime-v2.070.1 bf92678561b5ae662332cc5e104c39509fdfb130
    git -C $workdir/dmd tag -sm v2.070.1-b1 druntime-v2.070.1-b1 bf92678561b5ae662332cc5e104c39509fdfb130
    git -C $workdir/dmd tag -sm v2.070.2 druntime-v2.070.2 bf92678561b5ae662332cc5e104c39509fdfb130
    git -C $workdir/dmd tag -sm v2.071.0 druntime-v2.071.0 c6ac077a8d544fab65b1973b385c6f479697fb0e
    git -C $workdir/dmd tag -sm v2.071.0-b1 druntime-v2.071.0-b1 c6ac077a8d544fab65b1973b385c6f479697fb0e
    git -C $workdir/dmd tag -sm v2.071.0-b2 druntime-v2.071.0-b2 c6ac077a8d544fab65b1973b385c6f479697fb0e
    git -C $workdir/dmd tag -sm v2.071.1 druntime-v2.071.1 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.1-b1 druntime-v2.071.1-b1 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.1-b2 druntime-v2.071.1-b2 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.2 druntime-v2.071.2 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.2-b1 druntime-v2.071.2-b1 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.2-b2 druntime-v2.071.2-b2 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.2-b3 druntime-v2.071.2-b3 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.2-b4 druntime-v2.071.2-b4 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.2-b5 druntime-v2.071.2-b5 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.071.2-b6 druntime-v2.071.2-b6 0eade7404fa8bdea0d5088c3367eae7f7805ddce
    git -C $workdir/dmd tag -sm v2.072.0 druntime-v2.072.0 1394e0a7021a73660e41fe936b0fde7a12ee0b43
    git -C $workdir/dmd tag -sm v2.072.0-b1 druntime-v2.072.0-b1 f54fa2d97dbf7d5bb078d22737bdf78ee679d1c8
    git -C $workdir/dmd tag -sm v2.072.0-b2 druntime-v2.072.0-b2 45f2014d5b3f4965ccbda5c2dabb3f8e612924b4
    git -C $workdir/dmd tag -sm v2.072.1 druntime-v2.072.1 422c8f7b0f0e6598910737981074e0c45a4eb1b9
    git -C $workdir/dmd tag -sm v2.072.1-b1 druntime-v2.072.1-b1 422c8f7b0f0e6598910737981074e0c45a4eb1b9
    git -C $workdir/dmd tag -sm v2.072.2 druntime-v2.072.2 348c8bfebf2bdc453e2f631eac5e02c12de22dd6
    git -C $workdir/dmd tag -sm v2.072.2-b1 druntime-v2.072.2-b1 bf9d0019ff4ec0dd953612bc365875cc64f8409e
    git -C $workdir/dmd tag -sm v2.072.2-b2 druntime-v2.072.2-b2 348c8bfebf2bdc453e2f631eac5e02c12de22dd6
    git -C $workdir/dmd tag -sm v2.073.0 druntime-v2.073.0 0dc5d1dd68c2bcffb9a501f2e37ff28be3abd87e
    git -C $workdir/dmd tag -sm v2.073.0-b1 druntime-v2.073.0-b1 f6ddf6ccbcb41e7af47e6ed928d1e50c6b195d61
    git -C $workdir/dmd tag -sm v2.073.0-b2 druntime-v2.073.0-b2 f6ddf6ccbcb41e7af47e6ed928d1e50c6b195d61
    git -C $workdir/dmd tag -sm v2.073.0-rc1 druntime-v2.073.0-rc1 0dc5d1dd68c2bcffb9a501f2e37ff28be3abd87e
    git -C $workdir/dmd tag -sm v2.073.1 druntime-v2.073.1 0dc5d1dd68c2bcffb9a501f2e37ff28be3abd87e
    git -C $workdir/dmd tag -sm v2.073.1-b1 druntime-v2.073.1-b1 0dc5d1dd68c2bcffb9a501f2e37ff28be3abd87e
    git -C $workdir/dmd tag -sm v2.073.1-b2 druntime-v2.073.1-b2 0dc5d1dd68c2bcffb9a501f2e37ff28be3abd87e
    git -C $workdir/dmd tag -sm v2.073.2 druntime-v2.073.2 e9d0e1255b8ce2867ad8df632bdbc242b5992224
    git -C $workdir/dmd tag -sm v2.073.2-b1 druntime-v2.073.2-b1 e9d0e1255b8ce2867ad8df632bdbc242b5992224
    git -C $workdir/dmd tag -sm v2.074.0 druntime-v2.074.0 f056b99f98eb86e04ab06170feda8d4ad5483faa
    git -C $workdir/dmd tag -sm v2.074.0-b1 druntime-v2.074.0-b1 644d6fbf0d0f57382c9b555a718f18bb96f40455
    git -C $workdir/dmd tag -sm v2.074.0-b2 druntime-v2.074.0-b2 644d6fbf0d0f57382c9b555a718f18bb96f40455
    git -C $workdir/dmd tag -sm v2.074.0-rc1 druntime-v2.074.0-rc1 f056b99f98eb86e04ab06170feda8d4ad5483faa
    git -C $workdir/dmd tag -sm v2.074.1 druntime-v2.074.1 9093cfe5237b9f31dfd07a0f6e9181106af5566d
    git -C $workdir/dmd tag -sm v2.074.1-b1 druntime-v2.074.1-b1 6ae1682fbd2d76d5cec33f90669ba5945884eb76
    git -C $workdir/dmd tag -sm v2.075.0 druntime-v2.075.0 6de130802d501180cdcfe5a2cd0b927aca85c3a7
    git -C $workdir/dmd tag -sm v2.075.0-b1 druntime-v2.075.0-b1 d1f5e4b993cc857ecc0619da3e82563787209078
    git -C $workdir/dmd tag -sm v2.075.0-b2 druntime-v2.075.0-b2 6de130802d501180cdcfe5a2cd0b927aca85c3a7
    git -C $workdir/dmd tag -sm v2.075.0-b3 druntime-v2.075.0-b3 6de130802d501180cdcfe5a2cd0b927aca85c3a7
    git -C $workdir/dmd tag -sm v2.075.0-b4 druntime-v2.075.0-b4 6de130802d501180cdcfe5a2cd0b927aca85c3a7
    git -C $workdir/dmd tag -sm v2.075.0-rc1 druntime-v2.075.0-rc1 6de130802d501180cdcfe5a2cd0b927aca85c3a7
    git -C $workdir/dmd tag -sm v2.075.1 druntime-v2.075.1 4392df180943f6f3095768cf85e09422dc891ffb
    git -C $workdir/dmd tag -sm v2.075.1-b1 druntime-v2.075.1-b1 4392df180943f6f3095768cf85e09422dc891ffb
    git -C $workdir/dmd tag -sm v2.076.0 druntime-v2.076.0 34d69c4cd54fb5b0daea28856c61412e7908022b
    git -C $workdir/dmd tag -sm v2.076.0-b1 druntime-v2.076.0-b1 34d69c4cd54fb5b0daea28856c61412e7908022b
    git -C $workdir/dmd tag -sm v2.076.0-b2 druntime-v2.076.0-b2 34d69c4cd54fb5b0daea28856c61412e7908022b
    git -C $workdir/dmd tag -sm v2.076.0-rc1 druntime-v2.076.0-rc1 34d69c4cd54fb5b0daea28856c61412e7908022b
    git -C $workdir/dmd tag -sm v2.076.1 druntime-v2.076.1 ec9a79e15d446863191308fd5e20febce2053546
    git -C $workdir/dmd tag -sm v2.076.1-b1 druntime-v2.076.1-b1 e07fa031919579bd2b48f1f7ebb634061bd3daca
    git -C $workdir/dmd tag -sm v2.077.0 druntime-v2.077.0 c1eb992e3c7207f09aad3f69dabde03a946530c8
    git -C $workdir/dmd tag -sm v2.077.0-beta.1 druntime-v2.077.0-beta.1 816a6192595ca317c47f26bf44605b00f82ca7d0
    git -C $workdir/dmd tag -sm v2.077.0-beta.2 druntime-v2.077.0-beta.2 c1eb992e3c7207f09aad3f69dabde03a946530c8
    git -C $workdir/dmd tag -sm v2.077.0-rc.1 druntime-v2.077.0-rc.1 c1eb992e3c7207f09aad3f69dabde03a946530c8
    git -C $workdir/dmd tag -sm v2.077.1 druntime-v2.077.1 7c8ca6a4f0f3d4eb7564e00d4d770044ba8b889d
    git -C $workdir/dmd tag -sm v2.077.1-beta.1 druntime-v2.077.1-beta.1 7c8ca6a4f0f3d4eb7564e00d4d770044ba8b889d
    git -C $workdir/dmd tag -sm v2.078.0 druntime-v2.078.0 0fce87b5ed9666ed21d29cb6a80b0e456cc3a25e
    git -C $workdir/dmd tag -sm v2.078.0-beta.1 druntime-v2.078.0-beta.1 2f479ea95759b851f4237d4235b569cbb0b26a8f
    git -C $workdir/dmd tag -sm v2.078.0-rc.1 druntime-v2.078.0-rc.1 0fce87b5ed9666ed21d29cb6a80b0e456cc3a25e
    git -C $workdir/dmd tag -sm v2.078.1 druntime-v2.078.1 e5512c454cd53dbe1e8da93648aa9d6ea15f7bcf
    git -C $workdir/dmd tag -sm v2.078.1-beta.1 druntime-v2.078.1-beta.1 e5512c454cd53dbe1e8da93648aa9d6ea15f7bcf
    git -C $workdir/dmd tag -sm v2.078.2 druntime-v2.078.2 c4bc836402fd3d266c34ec18bc3c6ae4712d9449
    git -C $workdir/dmd tag -sm v2.078.2-beta.1 druntime-v2.078.2-beta.1 c4bc836402fd3d266c34ec18bc3c6ae4712d9449
    git -C $workdir/dmd tag -sm v2.078.3 druntime-v2.078.3 c4bc836402fd3d266c34ec18bc3c6ae4712d9449
    git -C $workdir/dmd tag -sm v2.079.0 druntime-v2.079.0 87656c3bf3661cbd7dca2eb2cbff48df2c022b52
    git -C $workdir/dmd tag -sm v2.079.0-beta.1 druntime-v2.079.0-beta.1 0bf6db721ff5d8a38237617e6eb4c7835d447110
    git -C $workdir/dmd tag -sm v2.079.0-beta.2 druntime-v2.079.0-beta.2 89745f5c7bd1fa790e786fe6ad2efa9a2b95dcee
    git -C $workdir/dmd tag -sm v2.079.0-rc.1 druntime-v2.079.0-rc.1 f49629453532fc8472028414962bebb681fe6efd
    git -C $workdir/dmd tag -sm v2.079.1 druntime-v2.079.1 17f2df3293327a291f1738078a2517e7595ad293
    git -C $workdir/dmd tag -sm v2.079.1-beta.1 druntime-v2.079.1-beta.1 17f2df3293327a291f1738078a2517e7595ad293
    git -C $workdir/dmd tag -sm v2.080.0 druntime-v2.080.0 a1d2a28841aec8f0b77f71ba5baea1a71aa309f8
    git -C $workdir/dmd tag -sm v2.080.0-beta.1 druntime-v2.080.0-beta.1 a1d2a28841aec8f0b77f71ba5baea1a71aa309f8
    git -C $workdir/dmd tag -sm v2.080.0-rc.1 druntime-v2.080.0-rc.1 a1d2a28841aec8f0b77f71ba5baea1a71aa309f8
    git -C $workdir/dmd tag -sm v2.080.1 druntime-v2.080.1 1d72cc43467bf3ceb1aa9cf837313a2d0f83ea2b
    git -C $workdir/dmd tag -sm v2.080.1-beta.1 druntime-v2.080.1-beta.1 1d72cc43467bf3ceb1aa9cf837313a2d0f83ea2b
    git -C $workdir/dmd tag -sm v2.081.0 druntime-v2.081.0 231c8d85cb3ac9367fbeae2c98025f2c4d197708
    git -C $workdir/dmd tag -sm v2.081.0-beta.1 druntime-v2.081.0-beta.1 42e555ab6187a84d7165c87ba21736fe0881c93f
    git -C $workdir/dmd tag -sm v2.081.0-beta.2 druntime-v2.081.0-beta.2 709270989ec493e18d82b5bb62b81208b570317f
    git -C $workdir/dmd tag -sm v2.081.0-rc.1 druntime-v2.081.0-rc.1 231c8d85cb3ac9367fbeae2c98025f2c4d197708
    git -C $workdir/dmd tag -sm v2.081.1 druntime-v2.081.1 005940a4ef1d2cc9e20361a064685ef874de37dd
    git -C $workdir/dmd tag -sm v2.081.1-beta.1 druntime-v2.081.1-beta.1 005940a4ef1d2cc9e20361a064685ef874de37dd
    git -C $workdir/dmd tag -sm v2.081.2 druntime-v2.081.2 df22381b0935ddae1322710fede499275f7b968b
    git -C $workdir/dmd tag -sm v2.081.2-beta.1 druntime-v2.081.2-beta.1 df22381b0935ddae1322710fede499275f7b968b
    git -C $workdir/dmd tag -sm v2.082.0 druntime-v2.082.0 d2e0f2c52668634d7e5e67ac7aa2f3e238877e05
    git -C $workdir/dmd tag -sm v2.082.0-beta.1 druntime-v2.082.0-beta.1 be132428871146e13695cade039e6ae5d9f95b1f
    git -C $workdir/dmd tag -sm v2.082.0-beta.2 druntime-v2.082.0-beta.2 1c60346c3d924ae888daf7f2842b5179c8303751
    git -C $workdir/dmd tag -sm v2.082.0-rc.1 druntime-v2.082.0-rc.1 d2e0f2c52668634d7e5e67ac7aa2f3e238877e05
    git -C $workdir/dmd tag -sm v2.082.1 druntime-v2.082.1 ca4b837c0560424bf609f0b23786ce153e2747f4
    git -C $workdir/dmd tag -sm v2.082.1-beta.1 druntime-v2.082.1-beta.1 ca4b837c0560424bf609f0b23786ce153e2747f4
    git -C $workdir/dmd tag -sm v2.083.0 druntime-v2.083.0 ec7b6590c3f80780a456a175c73db64c3a74a97c
    git -C $workdir/dmd tag -sm v2.083.0-beta.1 druntime-v2.083.0-beta.1 0bb71a3bdfd5131cb01c289c4cb255fb7c8a9b67
    git -C $workdir/dmd tag -sm v2.083.0-beta.2 druntime-v2.083.0-beta.2 ec7b6590c3f80780a456a175c73db64c3a74a97c
    git -C $workdir/dmd tag -sm v2.083.0-rc.1 druntime-v2.083.0-rc.1 ec7b6590c3f80780a456a175c73db64c3a74a97c
    git -C $workdir/dmd tag -sm v2.083.1 druntime-v2.083.1 ec7b6590c3f80780a456a175c73db64c3a74a97c
    git -C $workdir/dmd tag -sm v2.083.1-beta.1 druntime-v2.083.1-beta.1 ec7b6590c3f80780a456a175c73db64c3a74a97c
    git -C $workdir/dmd tag -sm v2.084.0 druntime-v2.084.0 c54593d256475b6c421b01bdfff958808ecadbaf
    git -C $workdir/dmd tag -sm v2.084.0-beta.1 druntime-v2.084.0-beta.1 f828e467bffd075464846982d54f1944584d341e
    git -C $workdir/dmd tag -sm v2.084.0-beta.2 druntime-v2.084.0-beta.2 f828e467bffd075464846982d54f1944584d341e
    git -C $workdir/dmd tag -sm v2.084.0-rc.1 druntime-v2.084.0-rc.1 f828e467bffd075464846982d54f1944584d341e
    git -C $workdir/dmd tag -sm v2.084.1 druntime-v2.084.1 5a463423ad55e853979ba0bf6b1675f023008ecb
    git -C $workdir/dmd tag -sm v2.084.1-beta.1 druntime-v2.084.1-beta.1 5a463423ad55e853979ba0bf6b1675f023008ecb
    git -C $workdir/dmd tag -sm v2.085.0 druntime-v2.085.0 f39321312ee05f3164e5fac98a6c93b56270d481
    git -C $workdir/dmd tag -sm v2.085.0-beta.1 druntime-v2.085.0-beta.1 f39321312ee05f3164e5fac98a6c93b56270d481
    git -C $workdir/dmd tag -sm v2.085.0-beta.2 druntime-v2.085.0-beta.2 f39321312ee05f3164e5fac98a6c93b56270d481
    git -C $workdir/dmd tag -sm v2.085.0-rc.1 druntime-v2.085.0-rc.1 f39321312ee05f3164e5fac98a6c93b56270d481
    git -C $workdir/dmd tag -sm v2.085.1 druntime-v2.085.1 e2bdc9c7a335b1f035d7753221aea5a282022976
    git -C $workdir/dmd tag -sm v2.085.1-beta.1 druntime-v2.085.1-beta.1 7608139c8ef77f0480ab2b1b0718a59bad7defe1
    git -C $workdir/dmd tag -sm v2.086.0 druntime-v2.086.0 b61d29ad6e1ada3bbc98d408104ef1afb5a3e642
    git -C $workdir/dmd tag -sm v2.086.0-beta.1 druntime-v2.086.0-beta.1 b85e5d61b7ec9ed732897b1714927ff415f5d301
    git -C $workdir/dmd tag -sm v2.086.0-rc.1 druntime-v2.086.0-rc.1 b61d29ad6e1ada3bbc98d408104ef1afb5a3e642
    git -C $workdir/dmd tag -sm v2.086.0-rc.2 druntime-v2.086.0-rc.2 b61d29ad6e1ada3bbc98d408104ef1afb5a3e642
    git -C $workdir/dmd tag -sm v2.086.1 druntime-v2.086.1 e57ecf4c6544a07864cf925d97ae9d27ba836399
    git -C $workdir/dmd tag -sm v2.086.1-beta.1 druntime-v2.086.1-beta.1 e57ecf4c6544a07864cf925d97ae9d27ba836399
    git -C $workdir/dmd tag -sm v2.087.0 druntime-v2.087.0 3ba98e659dc6857d7f5ad6383adc2b02510ce597
    git -C $workdir/dmd tag -sm v2.087.0-beta.1 druntime-v2.087.0-beta.1 c4dd1118bb291e55e84331d290b4e2b15d34e8a7
    git -C $workdir/dmd tag -sm v2.087.0-beta.2 druntime-v2.087.0-beta.2 c4dd1118bb291e55e84331d290b4e2b15d34e8a7
    git -C $workdir/dmd tag -sm v2.087.0-rc.1 druntime-v2.087.0-rc.1 c4dd1118bb291e55e84331d290b4e2b15d34e8a7
    git -C $workdir/dmd tag -sm v2.087.1 druntime-v2.087.1 aade3482e3004e88e6fcd28e247346c9fe9efd0f
    git -C $workdir/dmd tag -sm v2.087.1-beta.1 druntime-v2.087.1-beta.1 bb0bce70f58d26030dc2d169810e3f84a98d1f9c
    git -C $workdir/dmd tag -sm v2.088.0 druntime-v2.088.0 10c59a682dfcab834546dd7c79fdac480fa0187d
    git -C $workdir/dmd tag -sm v2.088.0-beta.1 druntime-v2.088.0-beta.1 397b38f1cd803ceb2310a1ec6aa17259659e67ea
    git -C $workdir/dmd tag -sm v2.088.0-beta.2 druntime-v2.088.0-beta.2 52881f5000771563f25536ac945e1f917ce594b4
    git -C $workdir/dmd tag -sm v2.088.0-rc.1 druntime-v2.088.0-rc.1 52881f5000771563f25536ac945e1f917ce594b4
    git -C $workdir/dmd tag -sm v2.088.1 druntime-v2.088.1 1a863bcef5a9911ff725d1c02227cc326b114664
    git -C $workdir/dmd tag -sm v2.088.1-beta.1 druntime-v2.088.1-beta.1 a040e3db764852ea2deaab536f2ba7bff7b80494
    git -C $workdir/dmd tag -sm v2.089.0 druntime-v2.089.0 b7a95119c42b91dc02d5707ae6db4df37a95cb12
    git -C $workdir/dmd tag -sm v2.089.0-beta.1 druntime-v2.089.0-beta.1 e17e1c38b8fdeb53289c47ea0822896fbf986945
    git -C $workdir/dmd tag -sm v2.089.0-beta.2 druntime-v2.089.0-beta.2 e17e1c38b8fdeb53289c47ea0822896fbf986945
    git -C $workdir/dmd tag -sm v2.089.0-rc.1 druntime-v2.089.0-rc.1 e17e1c38b8fdeb53289c47ea0822896fbf986945
    git -C $workdir/dmd tag -sm v2.089.1 druntime-v2.089.1 0ff7cc2f4874f6aac3b0becd93390bafc75bc5e9
    git -C $workdir/dmd tag -sm v2.089.1-beta.1 druntime-v2.089.1-beta.1 ace44186578269dd846634b0d5dfc2e2bc0f05bc
    git -C $workdir/dmd tag -sm v2.090.0 druntime-v2.090.0 805c37a9bc23045dfbc5b47b4d73e243c39da102
    git -C $workdir/dmd tag -sm v2.090.0-beta.1 druntime-v2.090.0-beta.1 712be502b7708057e4f70f77b3332bb77b1f6bc9
    git -C $workdir/dmd tag -sm v2.090.0-rc.1 druntime-v2.090.0-rc.1 33877b1e712cdbbdd04669cc26f97c26e3edd460
    git -C $workdir/dmd tag -sm v2.090.1 druntime-v2.090.1 3915d8e430e641b63e60cbddfce05138167db6cf
    git -C $workdir/dmd tag -sm v2.090.1-beta.1 druntime-v2.090.1-beta.1 20f5c0964ca29350a6c91130ac45c12f3710008b
    git -C $workdir/dmd tag -sm v2.091.0 druntime-v2.091.0 257aa3cc7756dafb91b39dbd57a0132f440c10df
    git -C $workdir/dmd tag -sm v2.091.0-beta.1 druntime-v2.091.0-beta.1 bfe8eb76ab2393f56bd9fb54bbc65c433ad3a655
    git -C $workdir/dmd tag -sm v2.091.0-beta.2 druntime-v2.091.0-beta.2 b8490c19f2eb64be456fb20879e4a9a05691f9fe
    git -C $workdir/dmd tag -sm v2.091.0-rc.1 druntime-v2.091.0-rc.1 c9762297cb202a157ca7084c0972716867caae76
    git -C $workdir/dmd tag -sm v2.091.1 druntime-v2.091.1 ce26f60733fee8d971724b1659b13e92df66a090
    git -C $workdir/dmd tag -sm v2.091.1-beta.1 druntime-v2.091.1-beta.1 8c846764781b726351c1ed30c5a4ad66b7620a8d
    git -C $workdir/dmd tag -sm v2.092.0 druntime-v2.092.0 c152a0cee1ea0205b6035bfda568d8bc52f0fc8b
    git -C $workdir/dmd tag -sm v2.092.0-beta.1 druntime-v2.092.0-beta.1 3f9bfc91a30516a3d01228a845566cf6431ddde1
    git -C $workdir/dmd tag -sm v2.092.0-rc.1 druntime-v2.092.0-rc.1 c152a0cee1ea0205b6035bfda568d8bc52f0fc8b
    git -C $workdir/dmd tag -sm v2.092.1 druntime-v2.092.1 b524311864adf05a8f8d721154fcf1c354543c8d
    git -C $workdir/dmd tag -sm v2.092.1-beta.1 druntime-v2.092.1-beta.1 b524311864adf05a8f8d721154fcf1c354543c8d
    git -C $workdir/dmd tag -sm v2.093.0 druntime-v2.093.0 fb02f4f8bc102320ecb112e6fb421f45d31f3b62
    git -C $workdir/dmd tag -sm v2.093.0-beta.1 druntime-v2.093.0-beta.1 fb02f4f8bc102320ecb112e6fb421f45d31f3b62
    git -C $workdir/dmd tag -sm v2.093.0-rc.1 druntime-v2.093.0-rc.1 fb02f4f8bc102320ecb112e6fb421f45d31f3b62
    git -C $workdir/dmd tag -sm v2.093.1 druntime-v2.093.1 50e00803084a499b6bba5f84ffa54ebd79685a5b
    git -C $workdir/dmd tag -sm v2.093.1-beta.1 druntime-v2.093.1-beta.1 50e00803084a499b6bba5f84ffa54ebd79685a5b
    git -C $workdir/dmd tag -sm v2.094.0 druntime-v2.094.0 7659f56ef916b7bab02af9274e6e1f5531f871bf
    git -C $workdir/dmd tag -sm v2.094.0-beta.1 druntime-v2.094.0-beta.1 7659f56ef916b7bab02af9274e6e1f5531f871bf
    git -C $workdir/dmd tag -sm v2.094.0-rc.1 druntime-v2.094.0-rc.1 7659f56ef916b7bab02af9274e6e1f5531f871bf
    git -C $workdir/dmd tag -sm v2.094.1 druntime-v2.094.1 bf554d252dab605d8da03455955c1687bcb7db9d
    git -C $workdir/dmd tag -sm v2.094.1-beta.1 druntime-v2.094.1-beta.1 9303c21905702f6e746c5ba6911203cf6efabb4d
    git -C $workdir/dmd tag -sm v2.094.2 druntime-v2.094.2 b4faadaffa7b962a8442a9c5f26538b369dbbb7e
    git -C $workdir/dmd tag -sm v2.094.2-beta.1 druntime-v2.094.2-beta.1 278daf49afdcd379ba2ebc81f0916ab42e8ef630
    git -C $workdir/dmd tag -sm v2.095.0 druntime-v2.095.0 92f73826aa27e2c663c369b4167c65ca2ffcf8c4
    git -C $workdir/dmd tag -sm v2.095.0-beta.1 druntime-v2.095.0-beta.1 92f73826aa27e2c663c369b4167c65ca2ffcf8c4
    git -C $workdir/dmd tag -sm v2.095.0-rc.1 druntime-v2.095.0-rc.1 92f73826aa27e2c663c369b4167c65ca2ffcf8c4
    git -C $workdir/dmd tag -sm v2.095.1 druntime-v2.095.1 3f75cae1d415a928741724be7374098f4c82d76d
    git -C $workdir/dmd tag -sm v2.095.1-beta.1 druntime-v2.095.1-beta.1 3f75cae1d415a928741724be7374098f4c82d76d
    git -C $workdir/dmd tag -sm v2.096.0 druntime-v2.096.0 0d7ec8010fffba3ff002f750955e7f8db8e96089
    git -C $workdir/dmd tag -sm v2.096.0-beta.1 druntime-v2.096.0-beta.1 78fe28ddc20e04fbefa54d2180f0a565c8969204
    git -C $workdir/dmd tag -sm v2.096.0-rc.1 druntime-v2.096.0-rc.1 150823db4d2504172a3e84b50487f52cb1210e2b
    git -C $workdir/dmd tag -sm v2.096.1 druntime-v2.096.1 89e2232db8fc6fa3b10850fc6af0b40fd195f70c
    git -C $workdir/dmd tag -sm v2.096.1-beta.1 druntime-v2.096.1-beta.1 89e2232db8fc6fa3b10850fc6af0b40fd195f70c
    git -C $workdir/dmd tag -sm v2.097.0 druntime-v2.097.0 c2ea24ae9f4c9fcc4a10e8dcd11c879170bd16cc
    git -C $workdir/dmd tag -sm v2.097.0-beta.1 druntime-v2.097.0-beta.1 0b855b0d5423865925aff9a2d1620010c1c0d108
    git -C $workdir/dmd tag -sm v2.097.0-rc.1 druntime-v2.097.0-rc.1 706815547a6d7219dc39ef2f392c6139b6e943db
    git -C $workdir/dmd tag -sm v2.097.1 druntime-v2.097.1 6b0de2de32c4746b95f08457d451e023173af985
    git -C $workdir/dmd tag -sm v2.097.1-beta.1 druntime-v2.097.1-beta.1 6b0de2de32c4746b95f08457d451e023173af985
    git -C $workdir/dmd tag -sm v2.097.2 druntime-v2.097.2 f978df34a48613492240e8398227419b14002bef
    git -C $workdir/dmd tag -sm v2.097.2-beta.1 druntime-v2.097.2-beta.1 4765ed327ca7368a4d719578a9f8329e18b92b14
    git -C $workdir/dmd tag -sm v2.098.0 druntime-v2.098.0 abd43eb4e760667fc4b1ebe1fe07d29340265596
    git -C $workdir/dmd tag -sm v2.098.0-beta.1 druntime-v2.098.0-beta.1 8783cdbfa2df64a565cb638ef75f885d17bce7f6
    git -C $workdir/dmd tag -sm v2.098.0-beta.2 druntime-v2.098.0-beta.2 8783cdbfa2df64a565cb638ef75f885d17bce7f6
    git -C $workdir/dmd tag -sm v2.098.0-beta.3 druntime-v2.098.0-beta.3 abd43eb4e760667fc4b1ebe1fe07d29340265596
    git -C $workdir/dmd tag -sm v2.098.0-rc.1 druntime-v2.098.0-rc.1 abd43eb4e760667fc4b1ebe1fe07d29340265596
    git -C $workdir/dmd tag -sm v2.098.1 druntime-v2.098.1 531e2b777aa0ef083f3082659372fad3d4c487fb
    git -C $workdir/dmd tag -sm v2.098.1-beta.1 druntime-v2.098.1-beta.1 9f331c5ca7201a3ccb4e3368611ffbc8a81bb4cd
    git -C $workdir/dmd tag -sm v2.099.0 druntime-v2.099.0 8631eff78bb6e227a0c1695fa5dacdc4091119b5
    git -C $workdir/dmd tag -sm v2.099.0-beta.1 druntime-v2.099.0-beta.1 25ad2a248e4eae5f2db85e9a62a255872a429815
    git -C $workdir/dmd tag -sm v2.099.0-rc.1 druntime-v2.099.0-rc.1 f59fc7417b88ba211046f81828b51129e2d72f62
    git -C $workdir/dmd tag -sm v2.099.1 druntime-v2.099.1 b87d7df8bf3244d772421008416263bab123e27e
    git -C $workdir/dmd tag -sm v2.099.1-beta.1 druntime-v2.099.1-beta.1 b87d7df8bf3244d772421008416263bab123e27e
    git -C $workdir/dmd tag -sm v2.100.0 druntime-v2.100.0 9c0d4f914e0817c9ee4eafc5a45c41130aa6b981
    git -C $workdir/dmd tag -sm v2.100.0-beta.1 druntime-v2.100.0-beta.1 27834edb5e1613e3abd43e09880c36d9fc961938
    git -C $workdir/dmd tag -sm v2.100.0-rc.1 druntime-v2.100.0-rc.1 9c0d4f914e0817c9ee4eafc5a45c41130aa6b981

    ##
    # ??? These druntime v2.064 tags aren't related to master/stable branches
    # Add the missing commits and tag them manually.
    git -C $workdir/dmd checkout druntime-v2.064beta3
    git -C $workdir/dmd am ../../patches/v2.064/0001-Merge-pull-request-644-from-WalterBright-fix11301.patch
    git -C $workdir/dmd tag -sm v2.064beta4 druntime-v2.064beta4
    git -C $workdir/dmd am ../../patches/v2.064/0002-Merge-pull-request-647-from-WalterBright-fix11344.patch
    git -C $workdir/dmd am ../../patches/v2.064/0003-Merge-pull-request-649-from-dawgfoto-fix11378.patch
    git -C $workdir/dmd am ../../patches/v2.064/0004-fix-2.064-merge-issue.patch
    git -C $workdir/dmd am ../../patches/v2.064/0005-add-missing-files-to-MANIFEST.patch
    git -C $workdir/dmd tag -sm v2.064 druntime-v2.064
    git -C $workdir/dmd tag -sm v2.064.2 druntime-v2.064.2

    ##
    # Ditto v2.066
    git -C $workdir/dmd checkout druntime-v2.066.0-rc2
    git -C $workdir/dmd am ../../patches/v2.066/0001-Merge-pull-request-926-from-WalterBright-manifest.patch
    git -C $workdir/dmd am ../../patches/v2.066/0002-Merge-pull-request-940-from-Dicebot-revert-745.patch
    git -C $workdir/dmd am ../../patches/v2.066/0003-Merge-pull-request-945-from-klamonte-master.patch
    git -C $workdir/dmd tag -sm v2.066.1-rc1 druntime-v2.066.1-rc1
    git -C $workdir/dmd tag -sm v2.066.1-rc2 druntime-v2.066.1-rc2

###############################################################################
elif [ "$1" = "filter-repo" ];
then
    ##
    # Test merging using filter-repo method.
    # ??? Rejected by committee.
    mkdir filter-repo
    git clone https://github.com/dlang/druntime filter-repo/druntime
    git clone https://github.com/dlang/dmd filter-repo/dmd
    git -C filter-repo/druntime filter-repo --to-subdirectory-filter druntime --tag-rename :druntime-
    git -C filter-repo/dmd remote add druntime ../druntime
    git -C filter-repo/dmd fetch druntime --tags
    git -C filter-repo/dmd merge --allow-unrelated-histories druntime/master
    git -C filter-repo/dmd checkout origin/stable -b stable
    git -C filter-repo/dmd merge --allow-unrelated-histories druntime/stable
    git -C filter-repo/dmd remote remove druntime
fi
